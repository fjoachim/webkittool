WebKitTool
==========

Version 0.5 - Source available on [GitHub](http://github.com/fjoachim/webkittool).

Copyright 2010 Joachim Fornallaz. All rights reserved.


Introduction
------------

This tool is used to generate graphic representation of web pages. It can create bitmap
formats such as PNG or JPEG and PDF documents.


Requirements
------------

WebKitTool requires Mac OS X Tiger (v10.4) or later and runs on Intel and PPC Macs.


Installation
------------

WebKitTool consists of a single file which can be installed anywhere, preferably
in /usr/local/bin or ~/bin - make sure the file is executable.


Usage
-----

WebKitTool is a command line tool which is invoked like this:

    ./WebKitTool [OPTIONS] <web address> <output path>
    
The file extension of the output path defines the output format (pdf, png or jpg).


The general options are:

* `-w, --browserwidth`

    Specifies the width in pixel of the virtual browser window.

For PDF files, you can use following options:

* `-p, --paginage`

    Creates multiple pages (A4 format) instead of one big page. 

* `-o, --orientation`

    Sets the page orientation: 'portrait' (default) or 'landscape'.


Examples
--------

Creating a single page PDF of www.google.com:

    ./WebKitTool www.google.com google.pdf
    
Creating a multipage PDF of www.engadget.com:

    ./WebKitTool -p http://www.engadget.com engadget.pdf


Additional Information
----------------------

If a web page you want to capture uses Flash, you might see the following output in the Terminal:

    Debugger() was called!

There is nothing to worry about.


Acknowledgements
----------------

Thanks to Dave Dribbin for his [ddcli framework](http://www.dribin.org/dave/software/#ddcli) which 
is used to parse the command line options.
