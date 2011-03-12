//IAMultipartRequestGenerator.h
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

@protocol IAMultipartRequestGeneratorDelegate <NSObject>

-(void)requestDidFailWithError:(NSError *)error;
-(void)requestDidFinishWithResponse:(NSData *)responseData;

@end

@interface IAMultipartRequestGenerator : NSObject {
    
    id<IAMultipartRequestGeneratorDelegate> delegate;
    CFMutableDataRef streamResponseData;
    
    
@private
    
    CFHTTPMessageRef requestMessage;
    CFReadStreamRef  readStream;
    NSString         *requestBoundary;
    NSMutableData    *requestData;
    
}

@property (retain, nonatomic) NSString *requestBoundary;
@property (retain, nonatomic) id<IAMultipartRequestGeneratorDelegate> delegate;
@property (readwrite) CFMutableDataRef streamResponseData;
@property (assign) CFHTTPMessageRef requestMessage;
@property (assign) CFReadStreamRef  readStream;

-(id)initWithUrl:(NSString *)urlString andRequestMethod:(NSString *)requestMethod;
-(void)setString:(NSString *)string forField:(NSString *)fieldName;
-(void)setData:(NSData *)data forField:(NSString *)fieldName;
-(void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)header;
-(void)startRequest;
-(void)closeRequest;

@end

@interface IAMultipartRequestGenerator (hidden)

-(CFHTTPMessageRef)generateBasicMessageRequestWithParams:(NSDictionary *)params;
-(void)openStream;
-(void)requestFinished;


@end
