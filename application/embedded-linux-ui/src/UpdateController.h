#pragma once

#include <QJsonObject>
#include <QLocalSocket>
#include <QObject>
#include <QString>
#include <QTimer>
#include <QVariantList>

class UpdateController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY statusChanged)
    Q_PROPERTY(bool desktopMode READ desktopMode NOTIFY statusChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY statusChanged)
    Q_PROPERTY(int progress READ progress NOTIFY statusChanged)
    Q_PROPERTY(QString state READ state NOTIFY statusChanged)
    Q_PROPERTY(QString message READ message NOTIFY statusChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY statusChanged)
    Q_PROPERTY(QString currentVersion READ currentVersion NOTIFY statusChanged)
    Q_PROPERTY(QString currentSlot READ currentSlot NOTIFY statusChanged)
    Q_PROPERTY(QString inactiveSlot READ inactiveSlot NOTIFY statusChanged)
    Q_PROPERTY(QString selectedPath READ selectedPath NOTIFY selectionChanged)
    Q_PROPERTY(QString selectedVersion READ selectedVersion NOTIFY selectionChanged)
    Q_PROPERTY(QString selectedSummary READ selectedSummary NOTIFY selectionChanged)
    Q_PROPERTY(bool selectedValid READ selectedValid NOTIFY selectionChanged)
    Q_PROPERTY(QVariantList images READ images NOTIFY imagesChanged)

public:
    explicit UpdateController(QObject *parent = nullptr);

    bool connected() const { return m_connected; }
    bool desktopMode() const { return m_desktopMode; }
    bool busy() const { return m_busy; }
    int progress() const { return m_progress; }
    QString state() const { return m_state; }
    QString message() const { return m_message; }
    QString errorString() const { return m_error; }
    QString currentVersion() const { return m_currentVersion; }
    QString currentSlot() const { return m_currentSlot; }
    QString inactiveSlot() const { return m_inactiveSlot; }
    QString selectedPath() const { return m_selectedPath; }
    QString selectedVersion() const { return m_selectedVersion; }
    QString selectedSummary() const { return m_selectedSummary; }
    bool selectedValid() const { return m_selectedValid; }
    QVariantList images() const { return m_images; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void selectImage(const QString &path);
    Q_INVOKABLE void installSelected();
    Q_INVOKABLE void rebootDevice();
    Q_INVOKABLE void confirmBoot();

signals:
    void statusChanged();
    void selectionChanged();
    void imagesChanged();

private:
    QJsonObject request(const QJsonObject &payload);
    void applyStatus(const QJsonObject &status);
    void enterDesktopMode();

    QString m_socketPath = QStringLiteral("/run/eld-update.sock");
    bool m_connected = false;
    bool m_desktopMode = false;
    bool m_busy = false;
    int m_progress = 0;
    QString m_state = QStringLiteral("idle");
    QString m_message = QStringLiteral("Ready to update");
    QString m_error;
    QString m_currentVersion;
    QString m_currentSlot;
    QString m_inactiveSlot;
    QString m_selectedPath;
    QString m_selectedVersion;
    QString m_selectedSummary;
    bool m_selectedValid = false;
    QVariantList m_images;
    QTimer m_pollTimer;
};
