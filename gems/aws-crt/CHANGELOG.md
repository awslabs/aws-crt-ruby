Unreleased Changes
------------------

0.4.1 (2025-1-28)
------------------
* Issue - Fix segfaults: CRC64NVME on machines with disabled AVX and uri parsing corner case

0.4.0 (2024-10-23)
------------------
* Issue - Update CMake to 3.9 

0.3.1 (2024-10-22)
------------------
* Issue - Prebuild s2n & aws-lc 


0.3.0 (2024-09-16)
------------------

* Feature - Support CRC64NVME checksums. 

0.2.1 (2024-06-13)
------------------

* Issue - Update to the latest aws-crt-ffi.

0.2.0 (2023-11-28)
------------------

* Feature - Support sigv4-s3express signing.

0.1.9 (2023-10-16)
------------------

* Issue - Update to the latest aws-crt-ffi -- fix Sigv4A on MacOS 14+.

0.1.8 (2023-03-28)
------------------

* Issue - Fix `warning: method redefined` warnings.

0.1.7 (2023-02-03)
------------------

* Issue - Update to the latest aws-crt-ffi.
* 
* Issue - Add support for overriding crt_bin_dir with `AWS_CRT_RUBY_BIN_DIR`.

0.1.6 (2022-08-12)
------------------

* Issue - Update to the latest aws-crt-ffi.

0.1.5 (2022-04-05)
------------------

* Issue - Update to the latest aws-crt-ffi.

0.1.4 (2022-03-15)
------------------

* Issue - Update the aws-lc submodule to a version that is not vulnerable to OpenSSL CVE-2022-0778 - Possible infinite loop in BN_mod_sqrt()

0.1.0 (2021-08-04)
------------------

* Feature - Initial preview release of `aws-crt` gem.
