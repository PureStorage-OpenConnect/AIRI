import __future__
import argparse
import libnfs
import os.path
import sys
from functools import partial
from multiprocessing import Pool, current_process


INTERFACE_ADDR = input("FlashBlade data VIP? ")
FILESYSTEM_NAME = input("filesystem name (where files in 'manifest' live)? ")

NFS_ROOT='nfs://{}/{}/'.format(INTERFACE_ADDR,FILESYSTEM_NAME)
WORKER_CTX={}

def get_name():
    return current_process().name

def worker_init(use_libnfs):
    if use_libnfs:
        nfs = libnfs.NFS(NFS_ROOT)
        def reader(path):
            fh = nfs.open(path, "rb")
            fh.read()
            fh.close()
    else:
        def reader(path):
            with open(path, "rb") as f:
                f.read()

    WORKER_CTX[get_name()] = reader

def worker(fname):
    f0 = fname.replace('\n', '')
    reader = WORKER_CTX[get_name()]
    reader(f0)

def read_manifest(base, use_libnfs=False):
    path = os.path.join(base, 'manifest')
    with open(path, "r") as mf:
        manifest = mf.read()
    return manifest

def main():
    parser = argparse.ArgumentParser(description='Read data')
    parser.add_argument('path',
                        help='Path where data and manifest are found')
    parser.add_argument('--libnfs', action='store_true',
                        help='Use libnfs (rather than kernel NFS client)')
    args = parser.parse_args()

    pool = Pool(initializer=worker_init, initargs=(args.libnfs,))
    manifest = read_manifest(args.path, use_libnfs=args.libnfs)
    pool.map(worker, manifest.split())

if __name__ == "__main__":
    main()
