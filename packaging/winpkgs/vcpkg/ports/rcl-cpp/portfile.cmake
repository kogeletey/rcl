vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO kogeletey/rcl
    REF v0.1.0
    SHA512 0
    HEAD_REF main
)

file(INSTALL "${SOURCE_PATH}/implementations/cpp/rcl.hpp" DESTINATION "${CURRENT_PACKAGES_DIR}/include")
file(INSTALL "${SOURCE_PATH}/implementations/cpp/rcl_lexer.hpp" DESTINATION "${CURRENT_PACKAGES_DIR}/include")
file(INSTALL "${SOURCE_PATH}/implementations/cpp/rcl_project.hpp" DESTINATION "${CURRENT_PACKAGES_DIR}/include")
file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/rcl-cpp" RENAME copyright)
