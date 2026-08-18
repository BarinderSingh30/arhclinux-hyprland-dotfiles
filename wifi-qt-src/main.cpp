// wifi-qt -- a small Qt Widgets wifi picker, replacing the rofi-based
// scripts/.local/bin/wifi-menu with a real window.
//
// Backend is the exact nmcli command set wifi-menu already proved out:
// scan/sort/dedupe by signal, connect (prompting for a password only when
// the network isn't already a saved profile), disconnect, forget, radio
// toggle. See wifi-menu's own header comment for the reasoning behind each
// of those choices -- it isn't repeated here.
//
// No Q_OBJECT subclasses on purpose: every signal/slot connection below is a
// stock Qt widget signal wired to a lambda, which needs no moc-generated
// code. That keeps the build a plain g++ invocation with no moc step.
//
// Styling comes from qt6ct's global stylesheet (theme-src/templates/
// pavucontrol-qt.qss.in) -- this app doesn't set its own QSS, it just
// inherits whatever qt6ct hands every Qt6 app that uses it as its platform
// theme, the same way pavucontrol-qt does.

#include <QApplication>
#include <QMainWindow>
#include <QListWidget>
#include <QListWidgetItem>
#include <QToolBar>
#include <QPushButton>
#include <QStatusBar>
#include <QInputDialog>
#include <QLineEdit>
#include <QMenu>
#include <QProcess>
#include <QFont>
#include <QFontDatabase>
#include <QTimer>
#include <QCloseEvent>

namespace {

struct Network {
    bool active = false;
    QString ssid;
    int signal = 0;
    QString security;
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

QString activeSsid(const QString &dev) {
    const QString out = runCmd({"-t", "-f", "active,ssid", "device", "wifi", "list",
                                 "ifname", dev, "--rescan", "no"});
    for (const QString &line : out.split('\n', Qt::SkipEmptyParts)) {
        const QStringList f = line.split(':');
        if (f.size() >= 2 && f[0] == "yes")
            return f[1];
    }
    return QString();
}

QList<Network> scanNetworks(const QString &dev) {
    const QString out = runCmd({"-t", "-f", "active,ssid,signal,security", "device", "wifi",
                                 "list", "ifname", dev, "--rescan", "yes"});
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

} // namespace

class WifiWindow : public QMainWindow {
public:
    WifiWindow() {
        setWindowTitle("Wifi");
        resize(420, 480);

        list = new QListWidget(this);
        list->setIconSize(QSize(1, 1)); // icons are drawn as glyph text, not pixmaps
        setCentralWidget(list);

        QFont iconFont("JetBrainsMono Nerd Font");
        list->setFont(QFont("Noto Sans", 11));
        listGlyphFont = iconFont;

        auto *bar = addToolBar("actions");
        bar->setMovable(false);
        radioButton = new QPushButton(this);
        connect(radioButton, &QPushButton::clicked, this, [this] { toggleRadio(); });
        bar->addWidget(radioButton);

        auto *refreshButton = new QPushButton(QString::fromUtf8(u8"\U000F0450  Refresh"), this);
        connect(refreshButton, &QPushButton::clicked, this, [this] { refresh(); });
        bar->addWidget(refreshButton);

        connect(list, &QListWidget::itemDoubleClicked, this, [this](QListWidgetItem *item) {
            connectToItem(item);
        });

        list->setContextMenuPolicy(Qt::CustomContextMenu);
        connect(list, &QListWidget::customContextMenuRequested, this, [this](const QPoint &pos) {
            showContextMenu(pos);
        });

        statusBar()->showMessage("Ready");

        dev = wifiDevice();
        if (dev.isEmpty()) {
            statusBar()->showMessage("No wifi device found");
            radioButton->setEnabled(false);
            return;
        }

        // Deferred rather than called here directly: refresh() blocks on
        // nmcli (a fresh scan takes a couple of seconds), and running it
        // inline would delay show() -- the window wouldn't appear at all
        // until the first scan finished. Scheduling it for right after the
        // event loop starts lets the empty window paint first.
        statusBar()->showMessage("Scanning...");
        QTimer::singleShot(50, this, [this] { refresh(); });
    }

private:
    QListWidget *list;
    QPushButton *radioButton;
    QFont listGlyphFont;
    QString dev;

    void refresh() {
        if (dev.isEmpty())
            return;
        const bool on = radioOn();
        radioButton->setText(on ? QString::fromUtf8(u8"\U000F092D  Turn wifi off")
                                 : QString::fromUtf8(u8"\U000F092D  Turn wifi on"));
        list->clear();

        if (!on) {
            statusBar()->showMessage("Wifi is off");
            return;
        }

        const QString active = activeSsid(dev);
        const QList<Network> nets = scanNetworks(dev);
        for (const Network &n : nets) {
            QString label = signalIcon(n.signal) + "  " + n.ssid;
            if (!n.security.isEmpty() && n.security != "--")
                label += "  " + lockGlyph();
            if (n.active)
                label += "  " + checkGlyph();

            auto *item = new QListWidgetItem(label, list);
            item->setFont(listGlyphFont);
            item->setData(Qt::UserRole, n.ssid);
            item->setData(Qt::UserRole + 1, n.security);
            item->setData(Qt::UserRole + 2, n.active);
        }
        statusBar()->showMessage(
            active.isEmpty() ? "Not connected" : "Connected: " + active);
    }

    void toggleRadio() {
        const bool on = radioOn();
        bool ok = false;
        runCmdCapturingError({"radio", "wifi", on ? "off" : "on"}, &ok);
        statusBar()->showMessage(on ? "Wifi disabled" : "Wifi enabled");
        QTimer::singleShot(on ? 100 : 1500, this, [this] { refresh(); });
    }

    void connectToItem(QListWidgetItem *item) {
        const QString ssid = item->data(Qt::UserRole).toString();
        const QString security = item->data(Qt::UserRole + 1).toString();
        const bool active = item->data(Qt::UserRole + 2).toBool();
        if (active)
            return;

        statusBar()->showMessage("Connecting to " + ssid + "...");
        setEnabled(false);

        bool ok = false;
        QString result;
        if (hasSavedProfile(ssid)) {
            result = runCmdCapturingError({"connection", "up", "id", ssid}, &ok);
        } else if (!security.isEmpty() && security != "--") {
            bool entered = false;
            const QString pw = QInputDialog::getText(
                this, "Password for " + ssid, "Password:",
                QLineEdit::Password, QString(), &entered);
            if (!entered) {
                setEnabled(true);
                statusBar()->showMessage("Cancelled");
                return;
            }
            result = runCmdCapturingError(
                {"device", "wifi", "connect", ssid, "password", pw, "ifname", dev}, &ok);
        } else {
            result = runCmdCapturingError(
                {"device", "wifi", "connect", ssid, "ifname", dev}, &ok);
        }

        setEnabled(true);
        statusBar()->showMessage(ok ? "Connected to " + ssid
                                     : "Failed to connect to " + ssid + ": " + result.trimmed());
        refresh();
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
        refresh();
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
