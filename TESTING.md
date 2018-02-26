# Testing Guide

Tests are written using the Minitest framework and stored inder `/test`. Model
fixtures are stored in `/test/fixtures`. Mocha stubs are used for most of the
API / Async assertions to prevent calls that would have undesired effects on
environments outside our control.

## Fixtures
Fixtures are loaded by `ActiveSupport::TestCase` and so follow all the normal
Rails testing conventions oulined in their [testing
guide](http://edgeguides.rubyonrails.org/testing.html#fixtures-in-action).

## FTP Tests
In testing we run a mock ftp warehouse server. There are 2 directories
associated with these tests `/test/ftp_skel` and `/test/ftp_mnt`. Before the
tests begin the contents of `/test/ftp_mnt` are wiped and files in
`/test/ftp_skel` are copied into `/test/ftp_mnt`.  `/test/ftp_mnt` is mounted to
the `/home/$FTP_USER` directory of the ftp container. This sets up a consistent
initial state for your tests and ensures that you do not destroy the contents of
`/test/ftp_skel` by accident during your tests. Because the contents of
`/test/ftp_mnt` are not wiped until the start of the next test you can examine
any files placed there during the last test run.
