#!/usr/bin/env python3
# encoding: utf-8

import os
import sys
import shutil
import zipfile
import time

LOCALVERSION = "v2.1"

INCLUDE_DIRS = ("META-INF", "script", "template")
INCLUDE_FILES = ("LICENSE", "README.md")

def local_path(*args):
    return os.path.join(os.getcwd(), *args)

def clean_action():
    for f in os.listdir(os.getcwd()):
        if f.endswith(".zip"):
            remove_path(local_path(f))

def mkdir(path):
    if os.path.exists(path):
        if not os.path.isdir(path):
            try:
                os.remove(path)
            except:
                pass
        else:
            return
    os.makedirs(path)

def file2file(src, dst, move=False):
    mkdir(os.path.split(dst)[0])
    if move:
        shutil.move(src, dst)
    else:
        shutil.copyfile(src, dst)
    return dst

def file2dir(src, dst, move=False):
    mkdir(dst)
    shutil.copy(src, dst)
    if move:
        os.remove(src)
    return os.path.join(dst, os.path.split(src)[1])

def remove_path(path):
    if os.path.isdir(path):
        shutil.rmtree(path)
    elif os.path.exists(path):
        os.remove(path)

def main():
    build_version = LOCALVERSION
    if len(sys.argv) >= 2:
        if sys.argv[1] == "clean":
            return clean_action()
        elif sys.argv[1].upper().startswith("T"):
            build_version += "-Test"
        elif sys.argv[1].upper().startswith("A"):
            build_version += "-Alpha"
        elif sys.argv[1].upper().startswith("R"):
            pass
        else:
            build_version += "-Beta"
    else:
        build_version += "-Beta"
    if len(sys.argv) >= 3:
        build_version += sys.argv[2]

    build_date = time.strftime("%Y.%m.%d", time.localtime(time.time()))

    print("\nMagisk Manager Recovery Tool Build Script")
    print("\nLocal Version: %s\nBuild Date: %s" % (build_version, build_date))
    print("\nBuilding...")
    file2dir(local_path("script", "ac-1.in"), local_path(), move=True)
    try:
        with open(local_path("ac-1.in"), "r", encoding="utf-8") as f1:
            with open(local_path("script", "ac-1.in"), "w", encoding="utf-8", newline="\n") as f2:
                f2.write(f1.read().replace("@BUILD_VERSION@", build_version)
                                  .replace("@BUILD_DATE@", build_date))
        archive_file = local_path("MMRT-%s.zip" % build_version)
        remove_path(archive_file)
        with zipfile.ZipFile(archive_file, "w") as zip:
            for d in INCLUDE_DIRS:
                for root, dirs, files in os.walk(d):
                    for f in files:
                        zip.write(os.path.join(root, f),
                                  compress_type=zipfile.ZIP_DEFLATED)
            for f in INCLUDE_FILES:
                zip.write(local_path(f), arcname=f,
                          compress_type=zipfile.ZIP_DEFLATED)
        print("\nDone! Output file:", archive_file)
    except:
        remove_path(archive_file)
        raise
    finally:
        remove_path(local_path("script", "ac-1.in"))
        file2dir(local_path("ac-1.in"), local_path("script"), move=True)

if __name__ == "__main__":
    main()
