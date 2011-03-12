//IAMultipartRequestGenerator.m
//
//Easy Multipart Request Generator
//This program is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of 
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with this program. If not, see http://www.gnu.org/licenses/.

#import "IAMultipartRequestGenerator.h"

//That's the buffer size, if there are too short buffer errors, try making it bigger
#define kStreamBufferSize 1024

@implementation IAMultipartRequestGenerator

@synthesize requestBoundary, delegate, requestMessage, readStream, streamResponseData;

#pragma mark -
#pragma mark Request Callbacks

id callingObjectPointer;


void requestCallback (CFReadStreamRef readStream, CFStreamEventType event, void *data) {
    
    
    switch (event) {
            
        case kCFStreamEventHasBytesAvailable: {
            
            //The data from stream is stored in a byte array buffer before being appended to the CFMutableData object
            UInt8 buffer[kStreamBufferSize];
            CFIndex bytesRead = CFReadStreamRead(readStream, buffer, kStreamBufferSize);
            
            //Check if there is at least one byte available
            if(bytesRead > 0) {
                
                //If the buffer is too small, then an exception is returned. In that case, just make the buffer bigger
                @try {
                
                    CFDataAppendBytes([callingObjectPointer streamResponseData], buffer, bytesRead);
                    
                }
                
               @catch(NSException *e) {
                    
                   NSError *error = [NSError errorWithDomain:@"Unable to append bytes from stream to buffer. Try extending the buffer size." code:3 userInfo:NULL];
                   [[callingObjectPointer delegate] requestDidFailWithError:error];
                   [callingObjectPointer closeRequest];
                    
                }
                
            }
            
            
        }
            
            
            break;
            
        case kCFStreamEventErrorOccurred: {
            
            CFStreamError error = CFReadStreamGetError(readStream);
            NSError *streamError = [NSError errorWithDomain:nil code:error.error userInfo:NULL];
            
            [callingObjectPointer closeRequest];
            [[callingObjectPointer delegate] requestDidFailWithError:streamError];
            
            
        }
            
            break;
            
        case kCFStreamEventEndEncountered: {
            
            [callingObjectPointer requestFinished];
            
            
        }
            break;
            
    };
    
    
    
}



#pragma mark -
#pragma mark init

- (id)initWithUrl:(NSString *)urlString andRequestMethod:(NSString *)requestMethod
{
    self = [super init];
    if (self) {
        
        requestData     = [[NSMutableData alloc] init];
        //We won't be checking if the request data doesn't contain the boundary, it's very unlikely. But if
        //it does, change this string to your liking
        requestBoundary = [NSString stringWithString:@"AaB03x"];
        
        [requestData appendData:[[NSString stringWithFormat:@"--%@\r\n", requestBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        self.requestMessage = [self generateBasicMessageRequestWithParams:[NSDictionary dictionaryWithObjectsAndKeys:urlString, @"url", requestMethod, @"requestMethod", nil]];
        
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=\"%@\"", requestBoundary];
       
        [self setValue:contentType forHTTPHeaderField:@"Content-Type"];
        
    }
    
    return self;
}

#pragma mark -
#pragma mark Request Generating

-(void)setString:(NSString *)string forField:(NSString *)fieldName {
    
    
    NSMutableString *fieldString = [NSMutableString string];
 
    [fieldString appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", fieldName];
    [fieldString appendFormat:@"%@\r\n", string];
    [fieldString appendFormat:@"--%@\r\n", requestBoundary];
    
    [requestData appendData:[fieldString dataUsingEncoding:NSUTF8StringEncoding]];
        
    
}


-(void)setData:(NSData *)data forField:(NSString *)fieldName {
    
    NSMutableString *fieldString = [NSMutableString string];
    
    [fieldString appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"file\"\r\n", fieldName];
    [fieldString appendString:@"Content-Type: application/octet-stream\r\n\r\n"];
    
    [requestData appendData:[fieldString dataUsingEncoding:NSUTF8StringEncoding]];
    [requestData appendData:data];
    [requestData appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [requestData appendData:[[NSString stringWithFormat:@"--%@\r\n", requestBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    
}


-(CFHTTPMessageRef)generateBasicMessageRequestWithParams:(NSDictionary *)params {
    
    if (params != nil) {
        
        NSString *url = [NSString stringWithString:[params objectForKey:@"url"]];
        NSString *method = [NSString stringWithString:[params objectForKey:@"requestMethod"]];
        
        CFURLRef urlRef = CFURLCreateWithString(kCFAllocatorSystemDefault, (CFStringRef)url, NULL);
        
        CFHTTPMessageRef requestMsg = CFHTTPMessageCreateRequest(kCFAllocatorSystemDefault, (CFStringRef)method, urlRef, kCFHTTPVersion1_1);
        
        
        
        CFRelease(urlRef);
        
        return requestMsg;
        
    }
    
    else {
        
        return nil;
        
    }
    
}

-(void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)header {
    
    
    CFHTTPMessageSetHeaderFieldValue(requestMessage, (CFStringRef)header, (CFStringRef)value);
    
}


#pragma mark -
#pragma mark Staring Request


-(void)openStream {
    
    //This method is meant to be running in different thread
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    self.streamResponseData = CFDataCreateMutable(kCFAllocatorSystemDefault, kStreamBufferSize);
    CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    callingObjectPointer = self;
    
    CFRunLoopRun();
    
    [pool release];
    
    
}


-(void)startRequest {
    
    //Append the last boundary here
    [requestData appendData:[[NSString stringWithFormat:@"--%@--\r\n", requestBoundary] dataUsingEncoding:NSUTF8StringEncoding]];    
    
    CFHTTPMessageSetBody(requestMessage, (CFDataRef)requestData);

    //Setup the read stream with our request
    self.readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorSystemDefault, requestMessage);
    
    //Check to see if we can open a stream
    if(CFReadStreamOpen(readStream)) {
        
        //The request is going to run in a runloop, so we register the events that will trigger a callback
        CFOptionFlags streamFlags = kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered;
        //We don't need any callbacks for retaining or destroying here, so set it to NULL
        CFStreamClientContext clientContext = {0, NULL, NULL, NULL, NULL};
        
        //if we reqister our stream and callback, we spawn it inside another thread as
        //waiting for response can take some time depending on the request size
        if(CFReadStreamSetClient(readStream, streamFlags, requestCallback, &clientContext)) {
            
            [NSThread detachNewThreadSelector:@selector(openStream) toTarget:self withObject:nil];
            
        }
        
        
        else {
            
            NSError *error = [NSError errorWithDomain:@"Failed to start a read stream client" code:1 userInfo:NULL];
            
            [delegate requestDidFailWithError:error];
            
        }
        
        
        
    }
    
    
    else {
        
        
        NSError *error = [NSError errorWithDomain:@"Failed to open a read stream" code:2 userInfo:NULL];
        
        [delegate requestDidFailWithError:error];
        
        
    }

    
    
}


#pragma mark -
#pragma mark Finalizing request

-(void)requestFinished {
    
    //Notify the delegate with response
    
    NSData *data = [NSData dataWithData:(NSData *)streamResponseData];
    [delegate requestDidFinishWithResponse:data];
    [self closeRequest];
    
}



-(void)closeRequest {
    
    //Free any resources after the request has finished
    
    CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFReadStreamClose(readStream);
    CFRelease(streamResponseData);
    CFRelease(requestMessage);
    CFRelease(readStream);
    
    
}

#pragma mark -
#pragma mark Memory managment

- (void)dealloc
{
    [requestBoundary release];
    [requestData release];
    [super dealloc];

}

@end
