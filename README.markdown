##Easy multipart form data request generator
####author: Michal Tuszynski

Easy multipart form data request generator is a lightweight CFNetwork wrapper for sending multipart form data requests from iOS/Mac apps. Thanks to this, you can send images or other binary data over the internet. 

##Installation

###iOS
1) Open MultipartFormDataRequestGenerator.xcodeproj file

2) Copy the header and implmenentation file of IAMultipartRequestGenerator class to your own project

3) Add CFNetwork framework to your project (in xcode 3.x right-click-> add existing frameworks, in xcode 4 click on the project file->select your target->click the build phases tab->then select Link Binary With Libraries-> click the + button and add CFNetwork)

4) You're done!

###Mac
1) Open MultipartFormDataRequestGenerator.xcodeproj file

2) Copy the header and implmenentation file of IAMultipartRequestGenerator class to your own project

In Cocoa, CFNetwork is part of the Core Services, so you don't need to add CFNetwork to your project

##Usage

Usage is fairly simple. All you need to do, is to allocate a new object instance of IAMultipartRequestGenerator class, and set appropriate values for fields. For instance:

``
IAMultipartRequestGenerator *generator = [[IAMultipartRequestGenerator alloc] initWithUrl:@"http://imgur.com" andRequestMethod:@"POST"];

[generator setData:myData forField:@"image"];

[generator setString:developerKey forField:@"key"];

[generator setDelegate:self];

[generator startRequest];

[generator release];
``

For more usage information, check out the project wiki

##License

Easy Multipart Form Data Request Generator
Copyright (C) 2011  Michal Tuszynski

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
