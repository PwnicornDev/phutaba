#![Phutaba](https://cloud.githubusercontent.com/assets/173749/21355624/08f02130-c6cf-11e6-8c64-debb59bc9cc6.png)

An Imageboard engine based on [Wakaba](http://wakaba.c3.cx/s/web/wakaba_kareha).

## Installation
1. Modify `lib/site_config.pl.dist` and save as `lib/site_config.pl`
2. Modify `board/config.pl` to configure your board
3. Create `board/src/` and `board/thumb/` directories  
 - SQL tables are created automatically (if db user has `CREATE TABLE` permissions)
4. Create new boards by copying the structure and files from `board/`

### Apache modules needed
* suexec (apache2-suexec-custom)
* expires
* ssl
* headers
* rewrite
* cgid

### Perl modules needed (Ubuntu packages)
* libnet-dns-perl
* libjson-xs-perl
* libjson-perl
* libimage-exiftool-perl
* libgeo-ip-perl
* libtemplate-perl

### External libs
* imagemagick
* ffmpeg
