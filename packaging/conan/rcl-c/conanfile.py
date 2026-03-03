from conan import ConanFile
from conan.tools.files import copy
import os


class RclCConan(ConanFile):
    name = "rcl-c"
    version = "0.1.0"
    package_type = "library"
    settings = "os", "compiler", "build_type", "arch"
    exports_sources = "rcl.h", "rcl.c", "rcl_ast.c", "rcl_lexer.c", "rcl_parser.c", "rcl_parser_value.c", "rcl_project.c", "rcl_format.c", "rcl_convert.c"

    def package(self):
        copy(self, "*.h", self.source_folder, os.path.join(self.package_folder, "include"))
        copy(self, "*.c", self.source_folder, os.path.join(self.package_folder, "src"))

    def package_info(self):
        self.cpp_info.includedirs = ["include"]
        self.cpp_info.libdirs = []
        self.cpp_info.bindirs = []
