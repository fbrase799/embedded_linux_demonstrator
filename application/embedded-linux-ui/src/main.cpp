#include "SystemInfo.h"
#include "UpdateController.h"

#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Embedded Linux Demonstrator"));
    app.setOrganizationName(QStringLiteral("ELD"));
    app.setApplicationVersion(QStringLiteral(APP_VERSION));

    SystemInfo sysInfo;
    UpdateController updater;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("sysInfo"), &sysInfo);
    engine.rootContext()->setContextProperty(QStringLiteral("updater"), &updater);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("EmbeddedLinuxDemo", "Main");

    if (!engine.rootObjects().isEmpty())
        updater.confirmBoot();

    return app.exec();
}
