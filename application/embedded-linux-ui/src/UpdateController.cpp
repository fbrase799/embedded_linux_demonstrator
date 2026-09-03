#include "UpdateController.h"

#include <QCoreApplication>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QTimer>
#include <QVariantMap>

UpdateController::UpdateController(QObject *parent)
    : QObject(parent)
{
    connect(&m_pollTimer, &QTimer::timeout, this, &UpdateController::refresh);
    refresh();
}

QJsonObject UpdateController::request(const QJsonObject &payload)
{
    if (m_desktopMode)
        return {};

    QLocalSocket socket;
    socket.connectToServer(m_socketPath);
    if (!socket.waitForConnected(400)) {
        enterDesktopMode();
        return {};
    }

    socket.write(QJsonDocument(payload).toJson(QJsonDocument::Compact) + '\n');
    socket.flush();
    if (!socket.waitForReadyRead(15000))
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Update agent timed out")}};

    const QJsonDocument doc = QJsonDocument::fromJson(socket.readAll());
    if (!doc.isObject())
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Invalid agent response")}};
    m_connected = true;
    return doc.object();
}

void UpdateController::enterDesktopMode()
{
    if (m_desktopMode)
        return;
    m_desktopMode = true;
    m_connected = false;
    m_currentVersion = QCoreApplication::applicationVersion();
    m_currentSlot = QStringLiteral("A");
    m_inactiveSlot = QStringLiteral("B");
    m_message = QStringLiteral("Desktop mode: update agent is not running");
    m_state = QStringLiteral("desktop");
    emit statusChanged();
}

void UpdateController::applyStatus(const QJsonObject &status)
{
    if (status.isEmpty())
        return;
    m_connected = status.value(QStringLiteral("ok")).toBool(true);
    m_busy = status.value(QStringLiteral("busy")).toBool();
    m_progress = status.value(QStringLiteral("progress")).toInt();
    m_state = status.value(QStringLiteral("state")).toString(m_state);
    m_message = status.value(QStringLiteral("message")).toString(m_message);
    m_error = status.value(QStringLiteral("error")).toString();
    m_currentVersion = status.value(QStringLiteral("version")).toString(m_currentVersion);
    m_currentSlot = status.value(QStringLiteral("slot")).toString(m_currentSlot);
    m_inactiveSlot = status.value(QStringLiteral("inactive_slot")).toString(m_inactiveSlot);
    emit statusChanged();
}

void UpdateController::refresh()
{
    const QJsonObject status = request({{QStringLiteral("cmd"), QStringLiteral("status")}});
    applyStatus(status);

    const QJsonObject listed = request({{QStringLiteral("cmd"), QStringLiteral("list_images")}});
    m_images.clear();
    const QJsonArray images = listed.value(QStringLiteral("images")).toArray();
    for (const QJsonValue &value : images) {
        const QJsonObject obj = value.toObject();
        QVariantMap row;
        row.insert(QStringLiteral("path"), obj.value(QStringLiteral("path")).toString());
        row.insert(QStringLiteral("version"), obj.value(QStringLiteral("version")).toString());
        row.insert(QStringLiteral("valid"), obj.value(QStringLiteral("valid")).toBool());
        row.insert(QStringLiteral("error"), obj.value(QStringLiteral("error")).toString());
        row.insert(QStringLiteral("size"), obj.value(QStringLiteral("size")).toDouble());
        m_images.append(row);
    }
    emit imagesChanged();

    if (m_busy)
        m_pollTimer.start(500);
    else
        m_pollTimer.stop();
}

void UpdateController::selectImage(const QString &path)
{
    m_selectedPath = path;
    const QJsonObject info = request({
        {QStringLiteral("cmd"), QStringLiteral("inspect")},
        {QStringLiteral("path"), path},
    });

    if (m_desktopMode) {
        m_selectedVersion = QFileInfo(path).completeBaseName();
        m_selectedValid = path.endsWith(QLatin1String(".eldupdate")) || path.endsWith(QLatin1String(".update"));
        m_selectedSummary = m_selectedValid
            ? QStringLiteral("Selected %1 (desktop simulation)").arg(path)
            : QStringLiteral("Unsupported file type");
        emit selectionChanged();
        return;
    }

    m_selectedVersion = info.value(QStringLiteral("version")).toString();
    m_selectedValid = info.value(QStringLiteral("valid")).toBool();
    if (m_selectedValid) {
        m_selectedSummary = QStringLiteral("Version %1 for %2")
                                .arg(m_selectedVersion, info.value(QStringLiteral("compatible")).toString());
    } else {
        m_selectedSummary = info.value(QStringLiteral("error")).toString(QStringLiteral("Invalid image"));
    }
    emit selectionChanged();
}

void UpdateController::installSelected()
{
    if (m_selectedPath.isEmpty())
        return;

    if (m_desktopMode) {
        m_busy = true;
        m_progress = 0;
        m_state = QStringLiteral("installing");
        m_message = QStringLiteral("Simulated install");
        emit statusChanged();
        QTimer::singleShot(200, this, [this]() {
            m_progress = 100;
            m_busy = false;
            m_state = QStringLiteral("done");
            m_message = QStringLiteral("Desktop simulation complete. No device update was written.");
            emit statusChanged();
        });
        return;
    }

    m_busy = true;
    m_progress = 1;
    m_state = QStringLiteral("installing");
    m_message = QStringLiteral("Starting update");
    emit statusChanged();
    m_pollTimer.start(500);

    const QJsonObject result = request({
        {QStringLiteral("cmd"), QStringLiteral("install")},
        {QStringLiteral("path"), m_selectedPath},
    });
    applyStatus(result);
    if (result.contains(QStringLiteral("error")) && !result.value(QStringLiteral("ok")).toBool()) {
        m_error = result.value(QStringLiteral("error")).toString();
        m_state = QStringLiteral("error");
        m_busy = false;
        emit statusChanged();
    }
}

void UpdateController::rebootDevice()
{
    if (m_desktopMode) {
        m_message = QStringLiteral("Reboot is not available in desktop mode");
        emit statusChanged();
        return;
    }
    request({{QStringLiteral("cmd"), QStringLiteral("reboot")}});
}

void UpdateController::confirmBoot()
{
    if (m_desktopMode)
        return;
    request({{QStringLiteral("cmd"), QStringLiteral("confirm_boot")}});
    refresh();
}
