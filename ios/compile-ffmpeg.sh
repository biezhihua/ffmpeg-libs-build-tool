#! /usr/bin/env bash

source ../tools/colors.sh
source ../tools/common.sh
set -e

function make_ios_ffmpeg_config_params() {

    echo "--------------------"
    echo -e "${red}[*] make config params ${nc}"
    echo "--------------------"

    cfg_flags="$cfg_flags --prefix=$output_path"

    export COMMON_CFG_FLAGS=
    . ./config/module.sh

    # config
    cfg_flags="$cfg_flags ${COMMON_CFG_FLAGS}"

    #
    cfg_flags="$cfg_flags --enable-cross-compile"

    # Developer options (useful when working on FFmpeg itself):
    cfg_flags="$cfg_flags --disable-stripping"

    cfg_flags="$cfg_flags --arch=$target_arch"
    cfg_flags="$cfg_flags --target-os=darwin"
    cfg_flags="$cfg_flags --enable-static"
    cfg_flags="$cfg_flags --disable-shared"
    cfg_flags="$cfg_flags --enable-optimizations"
    cfg_flags="$cfg_flags --enable-debug"
    cfg_flags="$cfg_flags --enable-small"

    if [[ "$target_arch" = "i386" ]]; then

        xcrun_platform_name="iPhoneSimulator"

        xcrun_osversion="-mios-simulator-version-min=8.0"

        cfg_flags="$cfg_flags --disable-asm"
        cfg_flags="$cfg_flags --disable-mmx"
        cfg_flags="$cfg_flags --assert-level=2"

    elif [[ "$target_arch" = "x86_64" ]]; then

        xcrun_platform_name="iPhoneSimulator"

        xcrun_osversion="-mios-simulator-version-min=8.0"

        cfg_flags="$cfg_flags --disable-asm"
        cfg_flags="$cfg_flags --disable-mmx"
        cfg_flags="$cfg_flags --assert-level=2"

    elif [[ "$target_arch" = "arm64" ]]; then

        xcrun_platform_name="iPhoneOS"

        xcrun_osversion="-miphoneos-version-min=8.0"

        xcode_bitcode="-fembed-bitcode"

        gaspp_export="GASPP_FIX_XCODE5=1"

        cfg_flags="$cfg_flags --enable-pic"
        cfg_flags="$cfg_flags --enable-neon"

    elif [[ "$target_arch" = "armv7" ]]; then

        xcrun_platform_name="iPhoneOS"

        xcrun_osversion="-miphoneos-version-min=8.0"

        xcode_bitcode="-fembed-bitcode"

        cfg_flags="$cfg_flags --enable-pic"
        cfg_flags="$cfg_flags --enable-neon"

    elif [[ "$target_arch" = "armv7s" ]]; then

        xcrun_platform_name="iPhoneOS"

        xcrun_osversion="-miphoneos-version-min=8.0"

        xcode_bitcode="-fembed-bitcode"

        cfg_cpu="$cfg_cpu --cpu=swift"

        cfg_flags="$cfg_flags --enable-pic"
        cfg_flags="$cfg_flags --enable-neon"

    else
        echo "unknown architecture $target_arch";
        exit 1
    fi

    c_flags="$c_flags -arch $target_arch"
    c_flags="$c_flags $xcrun_osversion"
    c_flags="$c_flags $xcode_bitcode"
    ld_flags="$ld_flags"
    dep_libs="$c_flags"
    cfg_cpu="$cfg_cpu"

    echo "cfg_flags = $cfg_flags"
    echo ""
    echo "dep_libs = $dep_libs"
    echo ""
    echo "ld_flags = $ld_flags"
    echo ""
    echo "cfg_cpu = $cfg_cpu"
    echo ""
    echo "xcrun_platform_name = $xcrun_platform_name"
    echo ""
    echo "xcrun_osversion = $xcrun_osversion"
    echo ""
    echo "xcode_bitcode = $xcode_bitcode"
    echo ""
}

function make_ios_ffmpeg_product() {
    echo "--------------------"
    echo -e "${red}[*] compile openssl ${nc}"
    echo "--------------------"

    current_path=`pwd`
    cd ${source_path}

    echo "current_directory = ${source_path}"

    ./configure \
        ${cfg_flags} \
        --cc="$xcrun_cc" \
        ${cfg_cpu} \
        --extra-cflags="$c_flags" \
        --extra-cxxflags="$c_flags" \
        --extra-ldflags="$ld_flags $dep_libs"

    make clean
    make install -j8

    cp -r ${output_path}/include ${product_path}/include
    mkdir -p ${product_path}/lib
    cp -r ${output_path}/lib/* ${product_path}/lib/

    cd ${current_path}

    echo "product_path = ${product_path}"
    echo ""
    echo "product_path_include = ${product_path}/include"
    echo ""
    echo "product_path_lib = ${product_path}/lib"
    echo ""
}

#function make_arch_merge() {
#    for lib in ${libs}
#    do
#        file="$lib.a";
#        src=${product_path}/lib/${file}
#        output=${product_path}/lib/${file}
#        xcrun lipo -create ${src} -output ${output}
#        xcrun lipo -info ${output}
#    done
#}

function compile() {
    check_env
    check_ios_mac_host
    make_env_params
    make_ios_ffmpeg_config_params
    make_ios_or_mac_toolchain
    make_ios_ffmpeg_product
#    make_arch_merge
}

target_arch=$1
arch_all="armv7 armv7s arm64 i386 x86_64"
name=ffmpeg
build_root=`pwd`/build
build_name_openssl=
libs="libavcodec libavfilter libavformat libavutil libswscale libswresample"

function main() {
    current_path=`pwd`
    case "$target_arch" in
        armv7|armv7s|arm64|i386|x86_64)
            echo_arch
            compile
        ;;
        clean)
            for arch in ${arch_all}
            do
                if [[ -d ${name}-${arch} ]]; then
                    cd ${name}-${arch} && git clean -xdf && cd -
                fi
            done
            rm -rf ./build/src/${name}-*
            rm -rf ./build/output/${name}-*
            rm -rf ./build/product/${name}-*
            echo "clean complete"
        ;;
        check)
            echo_arch
        ;;
        *)
            echo_compile_usage
            exit 1
        ;;
    esac
}

main