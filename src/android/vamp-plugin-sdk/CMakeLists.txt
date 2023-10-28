cmake_minimum_required(VERSION 3.12)
project(vamp-plugin-sdk)

add_library(vamp-plugin-sdk STATIC
        src/vamp-hostsdk/Files.cpp
        src/vamp-hostsdk/PluginHostAdapter.cpp
        src/vamp-hostsdk/RealTime.cpp
        src/vamp-hostsdk/PluginBufferingAdapter.cpp
        src/vamp-hostsdk/PluginChannelAdapter.cpp
        src/vamp-hostsdk/PluginInputDomainAdapter.cpp
        src/vamp-hostsdk/PluginLoader.cpp
        src/vamp-hostsdk/PluginSummarisingAdapter.cpp
        src/vamp-hostsdk/PluginWrapper.cpp
        src/vamp-hostsdk/host-c.cpp
        src/vamp-hostsdk/acsymbols.c
)

target_include_directories(vamp-plugin-sdk PRIVATE .)
