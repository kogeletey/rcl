from conan import ConanFile
from conan.tools.files import copy
import os


class RclCppConan(ConanFile):
    name = "rcl-cpp"
    version = "0.1.0"
    package_type = "library"
    settings = "os", "compiler", "build_type", "arch"
    exports_sources = "rcl.hpp", "rcl.cpp", "rcl_ast.cpp", "rcl_lexer.cpp", "rcl_parser.cpp", "rcl_project.cpp", "rcl_format.cpp", "rcl_convert.cpp", "rcl_lexer.hpp", "rcl_project.hpp"

    def package(self):
        copy(self, "*.hpp", self.source_folder, os.path.join(self.package_folder, "include"))
        copy(self, "*.cpp", self.source_folder, os.path.join(self.package_folder, "src"))

    def package_info(self):
        self.cpp_info.includedirs = ["include"]
        self.cpp_info.libdirs = []
        self.cpp_info.bindirs = []
