// wifi-qt -- a small Qt Widgets wifi picker, replacing the rofi-based
// scripts/.local/bin/wifi-menu with a real window.
//
// Backend is the exact nmcli command set wifi-menu already proved out:
// scan/sort/dedupe by signal, connect (prompting for a password only when
// the network isn't already a saved profile), disconnect, forget, radio
// toggle. See wifi-menu's own header comment for the reasoning behind each
// of those choices -- it isn't repeated here.
//
// Startup does NOT scan for nearby networks -- only the currently connected
// network's details (device show + a --rescan no lookup), which is cheap.
// A full scan (--rescan yes, a couple of seconds) only happens when "Show
// networks" is clicked, on request rather than automatically.
//
// No Q_OBJECT subclasses on purpose: every signal/slot connection below is a
// stock Qt widget signal wired to a lambda, which needs no moc-generated
// code. That keeps the build a plain g++ invocation with no moc step.
//
// Styling comes from qt6ct's global stylesheet (theme-src/templates/
// qt-apps.qss.in) -- this app doesn't set its own QSS, it just inherits
// whatever qt6ct hands every Qt6 app that uses it as its platform theme,
// the same way pavucontrol-qt does.

#include <QApplication>
#include <QMainWindow>
#include <QListWidget>
#include <QListWidgetItem>
#include <QToolBar>
#include <QPushButton>
#include <QStatusBar>
#include <QLabel>
#include <QLineEdit>
#include <QMenu>
#include <QProcess>
#include <QFont>
#include <QTimer>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFrame>

namespace {

struct Network {
    bool active = false;
    QString ssid;
    int signal = 0;
    QString security;
};

struct ConnectionDetails {
    bool connected = false;
    QString ssid, ip, gateway, dns, mac, security, freq, rate;
    int signal = 0;
};

QString runCmd(const QStringList &args, int timeoutMs = 8000) {
    QProcess proc;
    proc.start("nmcli", args);
    if (!proc.waitForFinished(timeoutMs))
        return QString();
    return QString::fromUtf8(proc.readAllStandardOutput());
}

QString runCmdCapturingError(const QStringList &args, bool *ok, int timeoutMs = 15000) {
    QProcess proc;
    proc.start("nmcli", args);
    if (!proc.waitForFinished(timeoutMs)) {
        *ok = false;
        return "timed out";
    }
    *ok = (proc.exitStatus() == QProcess::NormalExit && proc.exitCode() == 0);
    return *ok ? QString::fromUtf8(proc.readAllStandardOutput())
                : QString::fromUtf8(proc.readAllStandardError());
}

QString wifiDevice() {
    const QString out = runCmd({"-t", "-f", "DEVICE,TYPE", "device"});
    for (const QString &line : out.split('\n', Qt::SkipEmptyParts)) {
        const QStringList f = line.split(':');
        if (f.size() >= 2 && f[1] == "wifi")
            return f[0];
    }
    return QString();
}

bool radioOn() {
    return runCmd({"radio", "wifi"}).trimmed() == "enabled";
}

// Cheap: device show plus a non-rescanning wifi list lookup for the one
// active row. No fresh scan, so this is safe to call on every open/refresh.
ConnectionDetails fetchConnectionDetails(const QString &dev) {
    ConnectionDetails d;
    const QString show = runCmd({"-t", "-f",
        "GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,GENERAL.HWADDR",
        "device", "show", dev});
    for (const QString &line : show.split('\n', Qt::SkipEmptyParts)) {
        const int idx = line.indexOf(':');
        if (idx < 0)
            continue;
        const QString key = line.left(idx);
        const QString val = line.mid(idx + 1);
        if (key == "GENERAL.CONNECTION") d.ssid = val;
        else if (key.startsWith("IP4.ADDRESS")) d.ip = val;
        else if (key == "IP4.GATEWAY") d.gateway = val;
        else if (key.startsWith("IP4.DNS")) {
            if (!d.dns.isEmpty())
                d.dns += ", ";
            d.dns += val;
        } else if (key == "GENERAL.HWADDR") {
            d.mac = val;
        }
    }
    d.connected = !d.ssid.isEmpty() && d.ssid != "--";
    if (!d.connected)
        return d;

    const QString wifiOut = runCmd({"-t", "-f", "active,ssid,signal,security,freq,rate",
                                     "device", "wifi", "list", "ifname", dev,
                                     "--rescan", "no"});
    for (const QString &line : wifiOut.split('\n', Qt::SkipEmptyParts)) {
        const QStringList f = line.split(':');
        if (f.size() >= 6 && f[0] == "yes" && f[1] == d.ssid) {
            d.signal = f[2].toInt();
            d.security = f[3];
            d.freq = f[4];
            d.rate = f[5];
            break;
        }
    }
    return d;
}

QList<Network> parseNetworks(const QString &out) {
    QList<Network> nets;
    for (const QString &line : out.split('\n', Qt::SkipEmptyParts)) {
        const QStringList f = line.split(':');
        if (f.size() < 4 || f[1].isEmpty())
            continue;
        Network n;
        n.active = (f[0] == "yes");
        n.ssid = f[1];
        n.signal = f[2].toInt();
        n.security = f[3];
        nets.append(n);
    }
    std::sort(nets.begin(), nets.end(), [](const Network &a, const Network &b) {
        return a.signal > b.signal;
    });
    QList<Network> deduped;
    for (const Network &n : nets) {
        bool seen = false;
        for (const Network &d : deduped)
            if (d.ssid == n.ssid) { seen = true; break; }
        if (!seen)
            deduped.append(n);
    }
    return deduped;
}

bool hasSavedProfile(const QString &ssid) {
    const QString out = runCmd({"-t", "-f", "NAME", "connection", "show"});
    for (const QString &line : out.split('\n', Qt::SkipEmptyParts))
        if (line == ssid)
            return true;
    return false;
}

QString signalIcon(int signal) {
    if (signal >= 70) return QStringLiteral(u"\U000F0928");
    if (signal >= 45) return QStringLiteral(u"\U000F0925");
    if (signal >= 20) return QStringLiteral(u"\U000F0922");
    return QStringLiteral(u"\U000F091F");
}

QString lockGlyph() { return QStringLiteral(u"\U000F033E"); }
QString checkGlyph() { return QStringLiteral(u"\U000F012C"); }

bool isSecured(const QString &security) {
    return !security.isEmpty() && security != "--";
}

} // namespace

class WifiWindow : public QMainWindow {
public:
    WifiWindow() {
        setWindowTitle("Wifi");
        resize(440, 520);

        glyphFont = QFont("JetBrainsMono Nerd Font");

        auto *central = new QWidget(this);
        auto *layout = new QVBoxLayout(central);
        layout->setContentsMargins(10, 10, 10, 10);
        layout->setSpacing(8);

        detailsLabel = new QLabel(central);
        detailsLabel->setWordWrap(true);
        detailsLabel->setTextFormat(Qt::RichText);
        layout->addWidget(detailsLabel);

        list = new QListWidget(central);
        list->setFont(QFont("Noto Sans", 11));
        list->hide();
        layout->addWidget(list, /* stretch */ 1);

        buildConnectPanel(central, layout);
        connectPanel->hide();

        setCentralWidget(central);

        auto *bar = addToolBar("actions");
        bar->setMovable(false);

        radioButton = new QPushButton(this);
        connect(radioButton, &QPushButton::clicked, this, [this] { toggleRadio(); });
        bar->addWidget(radioButton);

        showNetworksButton = new QPushButton(QString::fromUtf8(u8"\U000F0928  Show networks"), this);
        connect(showNetworksButton, &QPushButton::clicked, this, [this] { toggleNetworkList(); });
        bar->addWidget(showNetworksButton);

        refreshButton = new QPushButton(QString::fromUtf8(u8"\U000F0450  Refresh"), this);
        connect(refreshButton, &QPushButton::clicked, this, [this] { populateNetworkList(); });
        refreshButton->hide();
        bar->addWidget(refreshButton);

        connect(list, &QListWidget::itemClicked, this, [this](QListWidgetItem *item) {
            selectNetwork(item);
        });

        list->setContextMenuPolicy(Qt::CustomContextMenu);
        connect(list, &QListWidget::customContextMenuRequested, this, [this](const QPoint &pos) {
            showContextMenu(pos);
        });

        scanProc = new QProcess(this);
        connect(scanProc, &QProcess::finished, this,
                [this](int code, QProcess::ExitStatus status) { onScanFinished(code, status); });

        scanTimeoutTimer = new QTimer(this);
        scanTimeoutTimer->setSingleShot(true);
        connect(scanTimeoutTimer, &QTimer::timeout, this, [this] {
            // kill() is asynchronous -- finished() still fires afterwards
            // (with a crash exit status), so onScanFinished() does the
            // actual status/UI cleanup. This flag just makes its message
            // say "timed out" instead of the generic "Scan failed".
            scanTimedOut = true;
            scanProc->kill();
        });

        statusBar()->showMessage("Ready");

        dev = wifiDevice();
        if (dev.isEmpty()) {
            statusBar()->showMessage("No wifi device found");
            radioButton->setEnabled(false);
            showNetworksButton->setEnabled(false);
            return;
        }

        // Deferred rather than called here directly: even the cheap details
        // fetch is a couple of nmcli round-trips, and running it inline
        // would delay show() -- the window wouldn't appear until it
        // finished. Scheduling it for right after the event loop starts
        // lets the empty window paint first.
        QTimer::singleShot(50, this, [this] { refreshDetails(); });
    }

private:
    QLabel *detailsLabel;
    QListWidget *list;
    QPushButton *radioButton;
    QPushButton *showNetworksButton;
    QPushButton *refreshButton;
    QWidget *connectPanel;
    QLabel *connectLabel;
    QLineEdit *passwordEdit;
    QPushButton *connectButton;
    QPushButton *cancelButton;
    QFont glyphFont;
    QString dev;
    QString selectedSsid;
    QString selectedSecurity;
    QProcess *scanProc;
    QTimer *scanTimeoutTimer;
    bool scanTimedOut = false;

    void buildConnectPanel(QWidget *parent, QVBoxLayout *parentLayout) {
        connectPanel = new QFrame(parent);
        auto *panelLayout = new QVBoxLayout(connectPanel);
        panelLayout->setContentsMargins(0, 0, 0, 0);
        panelLayout->setSpacing(6);

        connectLabel = new QLabel(connectPanel);
        panelLayout->addWidget(connectLabel);

        passwordEdit = new QLineEdit(connectPanel);
        passwordEdit->setEchoMode(QLineEdit::Password);
        passwordEdit->setPlaceholderText("Password");
        connect(passwordEdit, &QLineEdit::returnPressed, this, [this] { performConnect(); });
        panelLayout->addWidget(passwordEdit);

        auto *buttonRow = new QHBoxLayout();
        connectButton = new QPushButton("Connect", connectPanel);
        connect(connectButton, &QPushButton::clicked, this, [this] { performConnect(); });
        cancelButton = new QPushButton("Cancel", connectPanel);
        connect(cancelButton, &QPushButton::clicked, this, [this] { hideConnectPanel(); });
        buttonRow->addWidget(connectButton);
        buttonRow->addWidget(cancelButton);
        panelLayout->addLayout(buttonRow);

        parentLayout->addWidget(connectPanel);
    }

    // Fields chosen for "detailed information about the connected network":
    // SSID, IP, gateway, DNS, signal, security, band/frequency, link speed,
    // MAC -- everything nmcli readily gives without a fresh scan.
    void refreshDetails() {
        if (dev.isEmpty())
            return;
        const bool on = radioOn();
        radioButton->setText(on ? QString::fromUtf8(u8"\U000F092D  Turn wifi off")
                                 : QString::fromUtf8(u8"\U000F092D  Turn wifi on"));
        showNetworksButton->setEnabled(on);

        if (!on) {
            detailsLabel->setText("<i>Wifi is off</i>");
            statusBar()->showMessage("Wifi is off");
            return;
        }

        const ConnectionDetails d = fetchConnectionDetails(dev);
        if (!d.connected) {
            detailsLabel->setText("<i>Not connected</i>");
            statusBar()->showMessage("Not connected");
            return;
        }

        detailsLabel->setText(QString(
            "<b>%1</b> %2<br>"
            "IP address: %3<br>"
            "Gateway: %4<br>"
            "DNS: %5<br>"
            "Signal: %6%<br>"
            "Security: %7<br>"
            "Frequency: %8<br>"
            "Link speed: %9<br>"
            "MAC: %10")
            .arg(d.ssid.toHtmlEscaped())
            .arg(checkGlyph())
            .arg(d.ip.isEmpty() ? "--" : d.ip.toHtmlEscaped())
            .arg(d.gateway.isEmpty() ? "--" : d.gateway.toHtmlEscaped())
            .arg(d.dns.isEmpty() ? "--" : d.dns.toHtmlEscaped())
            .arg(d.signal)
            .arg(isSecured(d.security) ? d.security.toHtmlEscaped() : "Open")
            .arg(d.freq.isEmpty() ? "--" : d.freq)
            .arg(d.rate.isEmpty() ? "--" : d.rate)
            .arg(d.mac.isEmpty() ? "--" : d.mac));
        statusBar()->showMessage("Connected: " + d.ssid);
    }

    void toggleNetworkList() {
        if (list->isVisible()) {
            list->hide();
            refreshButton->hide();
            hideConnectPanel();
            showNetworksButton->setText(QString::fromUtf8(u8"\U000F0928  Show networks"));
        } else {
            list->show();
            refreshButton->show();
            showNetworksButton->setText(QString::fromUtf8(u8"\U000F0928  Hide networks"));
            populateNetworkList();
        }
    }

    // Async rather than a blocking QProcess::waitForFinished(): a fresh scan
    // (--rescan yes) measured anywhere from ~2s to over 10s on this machine
    // depending on RF conditions, and a blocking wait doesn't pump Qt's
    // event loop -- so the window would look frozen for that whole stretch
    // (the "Scanning..." message set right before it never even got a
    // chance to paint), and a fixed timeout that was comfortably above the
    // fast case turned out to be BELOW the slow case, silently returning an
    // empty list ("sometimes not even show the available networks").
    // Letting the process run to completion in the background fixes both:
    // the UI stays responsive and there's no ceiling to exceed.
    void populateNetworkList() {
        if (scanProc->state() != QProcess::NotRunning)
            return;

        statusBar()->showMessage("Scanning...");
        list->setEnabled(false);
        list->clear();
        hideConnectPanel();

        scanTimeoutTimer->start(20000);
        scanProc->start("nmcli", {"-t", "-f", "active,ssid,signal,security", "device", "wifi",
                                   "list", "ifname", dev, "--rescan", "yes"});
    }

    void onScanFinished(int exitCode, QProcess::ExitStatus exitStatus) {
        scanTimeoutTimer->stop();
        list->setEnabled(true);

        if (scanTimedOut) {
            scanTimedOut = false;
            statusBar()->showMessage("Scan timed out after 20s -- try again");
            return;
        }

        if (exitStatus != QProcess::NormalExit || exitCode != 0) {
            const QString err = QString::fromUtf8(scanProc->readAllStandardError()).trimmed();
            statusBar()->showMessage(err.isEmpty() ? "Scan failed" : "Scan failed: " + err);
            return;
        }

        const QString out = QString::fromUtf8(scanProc->readAllStandardOutput());
        const QList<Network> nets = parseNetworks(out);
        for (const Network &n : nets) {
            QString label = signalIcon(n.signal) + "  " + n.ssid;
            if (isSecured(n.security))
                label += "  " + lockGlyph();
            if (n.active)
                label += "  " + checkGlyph();

            auto *item = new QListWidgetItem(label, list);
            item->setFont(glyphFont);
            item->setData(Qt::UserRole, n.ssid);
            item->setData(Qt::UserRole + 1, n.security);
            item->setData(Qt::UserRole + 2, n.active);
        }
        statusBar()->showMessage(QString("Found %1 network%2")
            .arg(nets.size()).arg(nets.size() == 1 ? "" : "s"));
    }

    void toggleRadio() {
        const bool on = radioOn();
        bool ok = false;
        runCmdCapturingError({"radio", "wifi", on ? "off" : "on"}, &ok);
        statusBar()->showMessage(on ? "Wifi disabled" : "Wifi enabled");
        if (on) {
            list->hide();
            refreshButton->hide();
            hideConnectPanel();
            showNetworksButton->setText(QString::fromUtf8(u8"\U000F0928  Show networks"));
        }
        QTimer::singleShot(on ? 100 : 1500, this, [this] { refreshDetails(); });
    }

    // Single click on a network row: show the inline connect panel rather
    // than a popup dialog, with the password field only when the network
    // actually needs one -- open networks and already-saved profiles skip
    // straight to a bare Connect button.
    void selectNetwork(QListWidgetItem *item) {
        const QString ssid = item->data(Qt::UserRole).toString();
        const QString security = item->data(Qt::UserRole + 1).toString();
        const bool active = item->data(Qt::UserRole + 2).toBool();
        if (active) {
            hideConnectPanel();
            return;
        }

        selectedSsid = ssid;
        selectedSecurity = security;

        connectLabel->setText("Connect to <b>" + ssid.toHtmlEscaped() + "</b>");
        const bool needsPassword = isSecured(security) && !hasSavedProfile(ssid);
        passwordEdit->setVisible(needsPassword);
        passwordEdit->clear();
        connectPanel->show();
        if (needsPassword)
            passwordEdit->setFocus();
    }

    void hideConnectPanel() {
        connectPanel->hide();
        passwordEdit->clear();
        selectedSsid.clear();
        list->clearSelection();
    }

    void performConnect() {
        if (selectedSsid.isEmpty())
            return;
        const QString ssid = selectedSsid;
        const QString security = selectedSecurity;
        const bool needsPassword = isSecured(security) && !hasSavedProfile(ssid);
        const QString pw = passwordEdit->text();
        if (needsPassword && pw.isEmpty()) {
            statusBar()->showMessage("Enter a password");
            return;
        }

        statusBar()->showMessage("Connecting to " + ssid + "...");
        setEnabled(false);
        // setEnabled(false) needs to actually paint before the blocking
        // connect call below, or the window just looks frozen for however
        // long the connect attempt takes (same issue the scan had -- see
        // populateNetworkList()'s comment).
        qApp->processEvents();

        bool ok = false;
        QString result;
        if (hasSavedProfile(ssid))
            result = runCmdCapturingError({"connection", "up", "id", ssid}, &ok);
        else if (needsPassword)
            result = runCmdCapturingError(
                {"device", "wifi", "connect", ssid, "password", pw, "ifname", dev}, &ok);
        else
            result = runCmdCapturingError(
                {"device", "wifi", "connect", ssid, "ifname", dev}, &ok);

        setEnabled(true);
        statusBar()->showMessage(ok ? "Connected to " + ssid
                                     : "Failed to connect to " + ssid + ": " + result.trimmed());
        hideConnectPanel();
        refreshDetails();
        if (list->isVisible())
            populateNetworkList();
    }

    void showContextMenu(const QPoint &pos) {
        QListWidgetItem *item = list->itemAt(pos);
        if (!item)
            return;
        const QString ssid = item->data(Qt::UserRole).toString();
        const bool active = item->data(Qt::UserRole + 2).toBool();

        QMenu menu(this);
        QAction *disconnectAction = active ? menu.addAction("Disconnect") : nullptr;
        QAction *forgetAction = menu.addAction("Forget " + ssid);
        QAction *chosen = menu.exec(list->viewport()->mapToGlobal(pos));

        if (!chosen)
            return;
        bool ok = false;
        if (chosen == disconnectAction) {
            runCmdCapturingError({"connection", "down", "id", ssid}, &ok);
            statusBar()->showMessage(ok ? "Disconnected from " + ssid : "Failed to disconnect");
        } else if (chosen == forgetAction) {
            runCmdCapturingError({"connection", "delete", "id", ssid}, &ok);
            statusBar()->showMessage(ok ? "Forgot " + ssid : "Failed to forget " + ssid);
        }
        refreshDetails();
        populateNetworkList();
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setApplicationName("wifi-qt");
    app.setOrganizationName("dotfiles");

    WifiWindow window;
    window.show();
    return app.exec();
}
