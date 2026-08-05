cmake_minimum_required(VERSION 3.16)
project(plasma-arcmenu VERSION 1.0.0)

set(PROJECT_DEP_VERSION "6.0.0")
set(QT_MIN_VERSION "6.6.0")
set(KF6_MIN_VERSION "6.0.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMFindQmlModule)
include(ECMQmlModule)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Core Qml Quick)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS I18n Package Config)
find_package(Plasma ${PROJECT_DEP_VERSION} REQUIRED)

plasma_install_package(package org.kde.plasma.arcmenu)

# Translations
ki18n_install(po)

# Optional standalone KCM registration stub (settings also available via plasmoid configure)
install(FILES kcm/kcm_arcmenu.json
        DESTINATION ${KDE_INSTALL_KSERVICESDIR}
        OPTIONAL)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
