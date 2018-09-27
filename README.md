DreamBox
========

> Recreates the DreamHost shared hosting environment as a Vagrant box.

**If you'd like to help test Dreambox 0.3.0-beta, please see [the 0.3.0 configuration notes](../../wiki/0.3.0) in the Wiki**

The `master` branch [will be archived soon](../../issues/64)

This project repo contains the code for [building the Dreambox base box][wiki_build]. To use Dreambox in your project, check out the ["Getting Started" section of the Wiki][getting_started].

## Package Versions

<<<<<<< HEAD
- Ubuntu - `14.04 LTS` (ubuntu/trusty64)
- PHP - `5.6.29`
- Apache - `2.2.31` (FastCGI)
- MySQL - `5.6.34-log`
=======
Ubuntu `14.04 LTS`
>>>>>>> 0.3.0-base

| Package           | Version    |
| ------------------|------------|
| ndn-php56         | 5.6.33-1   |
| ndn-php70         | 7.0.27-1   |
| ndn-php71         | 7.1.13-1   |
| ndn-apache22      | 2.2.31-5   |
| mysql-server-5.6  | 5.6.33     |

The following are installed, but may require additional configuration and/or packages (Contributions are welcome and appreciated):
* Perl
* PostgreSQL
* Python
* Ruby
* SQLite

See [the Wiki][getting_started] for additional documentation.

## References

- https://help.dreamhost.com/hc/en-us/articles/217141627-Supported-and-unsupported-technologies

[getting_started]: ../../wiki/Home
[wiki_build]: ../../wiki/Building-Dreambox
[upgrading_dreambox]: ../../wiki/Upgrading-Dreambox
