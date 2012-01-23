# Copyright (C) 2010 Ion Torrent Systems, Inc. All Rights Reserved
cmake_minimum_required (VERSION 2.6)
project (ion-plugins)
set(PROJECT_DESCRIPTION "Ion Torrent Plugins")
enable_testing()

include(../buildTools/cmake/CMakeLists.version.txt)
include(../buildTools/cmake/CMakeLists.compiler.txt)

# Where to install - override with: -DION_INSTALL_PREFIX
set(ION_INSTALL_PREFIX "/results" CACHE PATH "Ion Install Prefix")
set(CMAKE_INSTALL_PREFIX "${ION_INSTALL_PREFIX}" CACHE INTERNAL "Prefix prepended to install directories" FORCE)
set(CPACK_PACKAGING_INSTALL_PREFIX ${ION_INSTALL_PREFIX})
set(CPACK_SET_DESTDIR "ON")

configure_file (
	"${PROJECT_SOURCE_DIR}/debian/postinst.in"
	"${PROJECT_BINARY_DIR}/debian/postinst" @ONLY
)
configure_file (
	"${PROJECT_SOURCE_DIR}/debian/prerm.in"
	"${PROJECT_BINARY_DIR}/debian/prerm" @ONLY
)

# Alignment
#
install(DIRECTORY "${PROJECT_SOURCE_DIR}/Alignment" DESTINATION "plugins"
    USE_SOURCE_PERMISSIONS
    PATTERN ".svn" EXCLUDE)

# RunRecognition 
#
install(DIRECTORY "${PROJECT_SOURCE_DIR}/RunRecognitION" DESTINATION "plugins"
    USE_SOURCE_PERMISSIONS
    PATTERN ".svn" EXCLUDE)

# coverageAnalysis 
#
install(DIRECTORY "${PROJECT_SOURCE_DIR}/coverageAnalysis" DESTINATION "plugins"
    USE_SOURCE_PERMISSIONS
    PATTERN ".svn" EXCLUDE)

# variantCaller 
#
install(DIRECTORY "${PROJECT_SOURCE_DIR}/variantCaller" DESTINATION "plugins"
    USE_SOURCE_PERMISSIONS
    PATTERN ".svn" EXCLUDE)





install(FILES "${PROJECT_SOURCE_DIR}/plugin_functions" DESTINATION "plugins")


include(../buildTools/cmake/CMakeLists.cpack.txt)
#% nice to automate this
set(CPACK_DEBIAN_PACKAGE_DEPENDS "perl, python, ion-torrentr, ion-samita")
set(CPACK_PACKAGE_DESCRIPTION "Plugins for the Torrent Browser. These plugins, when present will be executed, post analysis pipeline run, to generate additional results.")
set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA
	${CMAKE_CURRENT_BINARY_DIR}/debian/postinst
	${CMAKE_CURRENT_BINARY_DIR}/debian/prerm
)
include(CPack)