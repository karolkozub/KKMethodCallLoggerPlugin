//
//  KKMethodCallLoggerTests.m
//  KKMethodCallLoggerPlugin
//
//  Created by Karol Kozub on 2014-12-28.
//  Copyright (c) 2014 Karol Kozub. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "KKMethodCallLogger.h"
#import <objc/runtime.h>


static NSMutableString *sLogString;


@interface KKMethodCallLoggerTests : XCTestCase

@property (nonatomic, strong) id object;

@end


@implementation KKMethodCallLoggerTests

- (void)setUp
{
  [super setUp];

  sLogString = [NSMutableString string];
  [KKMethodCallLogger setLogFunction:LogFunction];
}

- (void)tearDown
{
  self.object = nil;
  [KKMethodCallLogger stopLoggingMethodCallsForAllObjects];
  [KKMethodCallLogger setLogFunctionToDefault];
  sLogString = nil;

  [super tearDown];
}

- (void)testLoggingMethods
{
  self.object = [NSMutableArray array];
  [KKMethodCallLogger startLoggingMethodCallsForObject:self.object];

  [self.object count];
  [self.object addObject:@(1)];
  [self.object removeObject:@(1) inRange:NSMakeRange(0, 1)];

  XCTAssertEqualObjects(sLogString, @"-[__NSArrayM count]\n"
                                    @"-[__NSArrayM addObject:]\n"
                                    @"-[__NSArrayM removeObject:inRange:]\n");
}

- (void)testForwardingClassQueries
{
  self.object = [NSObject new];
  [KKMethodCallLogger startLoggingMethodCallsForObject:self.object];

  XCTAssertEqualObjects([self.object class], [NSObject class]);
}

- (void)testTurningOffLogging
{
  self.object = [NSMutableArray array];
  [KKMethodCallLogger startLoggingMethodCallsForObject:self.object];

  [self.object count];
  [KKMethodCallLogger stopLoggingMethodCallsForObject:self.object];

  [self.object addObject:@(1)];
  [self.object removeObject:@(1) inRange:NSMakeRange(0, 1)];

  XCTAssertEqualObjects(sLogString, @"-[__NSArrayM count]\n");
}

- (void)testLoggingWithName
{
  self.object = [NSMutableArray array];
  [KKMethodCallLogger startLoggingMethodCallsForObject:self.object withName:@"self.object"];

  [self.object count];

  XCTAssertEqualObjects(sLogString, @"-[self.object count]\n");
}

- (void)testChangingObjectName
{
  self.object = [NSMutableArray array];
  [KKMethodCallLogger startLoggingMethodCallsForObject:self.object];

  [self.object count];
  [KKMethodCallLogger startLoggingMethodCallsForObject:self.object withName:@"object"];

  [self.object addObject:@(1)];
  [KKMethodCallLogger startLoggingMethodCallsForObject:self.object withName:@"self.object"];

  [self.object removeAllObjects];

  XCTAssertEqualObjects(sLogString, @"-[__NSArrayM count]\n"
                                    @"-[object addObject:]\n"
                                    @"-[self.object removeAllObjects]\n");
}

- (void)testListingObjectMethodsIncludingAncestors
{
  self.object = @"test";

  [KKMethodCallLogger listMethodsForClass:[self.object class] includingAncestors:YES];

  NSArray *components = [[sLogString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
  NSArray *expectedComponents = @[@"__NSCFConstantString", @"-autorelease", @"-copyWithZone:", @"-release", @"-retain", @"-retainCount", @"__NSCFString", @"-UTF8String", @"-appendCharacters:length:", @"-appendFormat:", @"-appendString:", @"-cString", @"-cStringLength", @"-cStringUsingEncoding:", @"-characterAtIndex:", @"-classForCoder", @"-copyWithZone:", @"-deleteCharactersInRange:", @"-fastestEncoding", @"-finalize", @"-getCString:maxLength:encoding:", @"-getCharacters:range:", @"-getLineStart:end:contentsEnd:forRange:", @"-hasPrefix:", @"-hasSuffix:", @"-hash", @"-insertString:atIndex:", @"-isEqual:", @"-isEqualToString:", @"-isNSString__", @"-length", @"-mutableCopyWithZone:", @"-release", @"-replaceCharactersInRange:withString:", @"-replaceOccurrencesOfString:withString:options:range:", @"-retain", @"-retainCount", @"-setString:", @"-smallestEncoding", @"-substringWithRange:", @"-_fastCStringContents:", @"-_fastCharacterContents", @"-_isCString", @"-_isDeallocating", @"-_newSubstringWithRange:zone:", @"-_tryRetain", @"NSMutableString", @"-appendCharacters:length:", @"-appendFormat:", @"-appendString:", @"-classForCoder", @"-dd_appendSpaces:", @"-deleteCharactersInRange:", @"-initWithCapacity:", @"-insertString:atIndex:", @"-replaceCharactersInRange:withCString:length:", @"-replaceCharactersInRange:withCharacters:length:", @"-replaceCharactersInRange:withString:", @"-replaceOccurrencesOfString:withString:options:range:", @"-replacementObjectForPortCoder:", @"-setString:", @"-__oldnf_deleteAllCharactersFromSet:", @"-__oldnf_replaceAllAppearancesOfString:withString:", @"-__oldnf_replaceFirstAppearanceOfString:withString:", @"-__oldnf_replaceLastAppearanceOfString:withString:", @"-_cfAppendCString:length:", @"-_cfCapitalize:", @"-_cfLowercase:", @"-_cfNormalize:", @"-_cfPad:length:padIndex:", @"-_cfTrim:", @"-_cfTrimWS", @"-_cfUppercase:", @"-_replaceOccurrencesOfRegularExpressionPattern:withTemplate:options:range:", @"-_trimWithCharacterSet:", @"NSString", @"-LS_hasCaseInsensitivePrefix:", @"-LS_unescapedQueryValue", @"-UTF8String", @"-boolValue", @"-cString", @"-cStringLength", @"-cStringUsingEncoding:", @"-canBeConvertedToEncoding:", @"-capitalizedString", @"-capitalizedStringWithLocale:", @"-caseInsensitiveCompare:", @"-characterAtIndex:", @"-classForCoder", @"-commonPrefixWithString:options:", @"-compare:", @"-compare:options:", @"-compare:options:range:", @"-compare:options:range:locale:", @"-completePathIntoString:caseSensitive:matchesIntoArray:filterTypes:", @"-componentsByLanguage:", @"-componentsSeparatedByCharactersInSet:", @"-componentsSeparatedByString:", @"-containsString:", @"-copyWithZone:", @"-dataUsingEncoding:", @"-dataUsingEncoding:allowLossyConversion:", @"-decimalValue", @"-decomposedStringWithCanonicalMapping", @"-decomposedStringWithCompatibilityMapping", @"-description", @"-displayableString", @"-doubleValue", @"-encodeWithCoder:", @"-enumerateLinesUsingBlock:", @"-enumerateLinguisticTagsInRange:scheme:options:orthography:usingBlock:", @"-enumerateSubstringsInRange:options:usingBlock:", @"-fastestEncoding", @"-fileSystemRepresentation", @"-firstCharacter", @"-floatValue", @"-formatConfiguration", @"-getBytes:maxLength:filledLength:encoding:allowLossyConversion:range:remainingRange:", @"-getBytes:maxLength:usedLength:encoding:options:range:remainingRange:", @"-getCString:", @"-getCString:maxLength:", @"-getCString:maxLength:encoding:", @"-getCString:maxLength:range:remainingRange:", @"-getCharacters:", @"-getCharacters:range:", @"-getExternalRepresentation:extendedAttributes:forWritingToURLOrPath:usingEncoding:error:", @"-getFileSystemRepresentation:maxLength:", @"-getLineStart:end:contentsEnd:forRange:", @"-getParagraphStart:end:contentsEnd:forRange:", @"-hasPrefix:", @"-hasSuffix:", @"-hash", @"-init", @"-initWithBytesNoCopy:length:encoding:freeWhenDone:", @"-initWithCString:", @"-initWithCString:encoding:", @"-initWithCString:length:", @"-initWithCStringNoCopy:length:freeWhenDone:", @"-initWithCharacters:length:", @"-initWithCharactersNoCopy:length:freeWhenDone:", @"-initWithCoder:", @"-initWithContentsOfFile:", @"-initWithContentsOfFile:encoding:error:", @"-initWithContentsOfFile:usedEncoding:error:", @"-initWithContentsOfURL:", @"-initWithContentsOfURL:encoding:error:", @"-initWithContentsOfURL:usedEncoding:error:", @"-initWithData:encoding:", @"-initWithData:usedEncoding:", @"-initWithFormat:", @"-initWithFormat:arguments:", @"-initWithFormat:locale:", @"-initWithFormat:locale:arguments:", @"-initWithString:", @"-initWithUTF8String:", @"-intValue", @"-integerValue", @"-isAbsolutePath", @"-isCaseInsensitiveLike:", @"-isEqual:", @"-isEqualToString:", @"-isLike:", @"-isNSString__", @"-lastPathComponent", @"-length", @"-lengthOfBytesUsingEncoding:", @"-lineRangeForRange:", @"-linguisticTagsInRange:scheme:options:orthography:tokenRanges:", @"-localizedCaseInsensitiveCompare:", @"-localizedCaseInsensitiveContainsString:", @"-localizedCompare:", @"-localizedStandardCompare:", @"-longLongValue", @"-lossyCString", @"-lowercaseString", @"-lowercaseStringWithLocale:", @"-matchesPattern:", @"-matchesPattern:caseInsensitive:", @"-maximumLengthOfBytesUsingEncoding:", @"-mutableCopyWithZone:", @"-paragraphRangeForRange:", @"-pathComponents", @"-pathExtension", @"-pinyinStringFromPinyinWithToneNumber", @"-precomposedStringWithCanonicalMapping", @"-precomposedStringWithCompatibilityMapping", @"-propertyList", @"-propertyListFromStringsFileFormat", @"-queryToDict", @"-quotedStringRepresentation", @"-rangeOfCharacterFromSet:", @"-rangeOfCharacterFromSet:options:", @"-rangeOfCharacterFromSet:options:range:", @"-rangeOfComposedCharacterSequenceAtIndex:", @"-rangeOfComposedCharacterSequencesForRange:", @"-rangeOfString:", @"-rangeOfString:options:", @"-rangeOfString:options:range:", @"-rangeOfString:options:range:locale:", @"-replacementObjectForPortCoder:", @"-scriptingBeginsWith:", @"-scriptingContains:", @"-scriptingEndsWith:", @"-scriptingIsEqualTo:", @"-scriptingIsGreaterThan:", @"-scriptingIsGreaterThanOrEqualTo:", @"-scriptingIsLessThan:", @"-scriptingIsLessThanOrEqualTo:", @"-significantText", @"-simplifiedChineseCompare:", @"-smallestEncoding", @"-standardizedURLPath", @"-stringByAbbreviatingWithTildeInPath", @"-stringByAddingPercentEncodingWithAllowedCharacters:", @"-stringByAddingPercentEscapes", @"-stringByAddingPercentEscapesUsingEncoding:", @"-stringByAppendingFormat:", @"-stringByAppendingPathComponent:", @"-stringByAppendingPathExtension:", @"-stringByAppendingString:", @"-stringByApplyingPinyinToneMarkToFirstSyllableWithToneNumber:", @"-stringByConvertingPathToURL", @"-stringByConvertingURLToPath", @"-stringByDeletingLastPathComponent", @"-stringByDeletingPathExtension", @"-stringByExpandingTildeInPath", @"-stringByFoldingWithOptions:locale:", @"-stringByPaddingToLength:withString:startingAtIndex:", @"-stringByRemovingPercentEncoding", @"-stringByRemovingPercentEscapes", @"-stringByReplacingCharactersInRange:withString:", @"-stringByReplacingOccurrencesOfString:withString:", @"-stringByReplacingOccurrencesOfString:withString:options:range:", @"-stringByReplacingPercentEscapesUsingEncoding:", @"-stringByResolvingSymlinksInPath", @"-stringByStandardizingPath", @"-stringByStrippingDiacritics", @"-stringByTrimmingCharactersInSet:", @"-stringMarkingUpcaseTransitionsWithDelimiter2:", @"-stringsByAppendingPaths:", @"-strokeStringFromNumberString", @"-substringFromIndex:", @"-substringToIndex:", @"-substringWithRange:", @"-toneFromPinyinSyllableWithNumber", @"-traditionalChinesePinyinCompare:", @"-traditionalChineseZhuyinCompare:", @"-uppercaseString", @"-uppercaseStringWithLocale:", @"-urlPathRelativeToPath:", @"-writeToFile:atomically:", @"-writeToFile:atomically:encoding:error:", @"-writeToURL:atomically:", @"-writeToURL:atomically:encoding:error:", @"-zhuyinSyllableFromPinyinSyllable", @"-__escapeString5991", @"-__oldnf_componentsSeparatedBySet:", @"-__oldnf_containsChar:", @"-__oldnf_containsCharFromSet:", @"-__oldnf_containsString:", @"-__oldnf_copyToUnicharBuffer:saveLength:", @"-__oldnf_stringWithSeparator:atFrequency:", @"-_allowsDirectEncoding", @"-_caseInsensitiveNumericCompare:", @"-_cfTypeID", @"-_copyFormatStringWithConfiguration:", @"-_createSubstringWithRange:", @"-_encodingCantBeStoredInEightBitCFString", @"-_fastCStringContents:", @"-_fastCharacterContents", @"-_fastestEncodingInCFStringEncoding", @"-_flushRegularExpressionCaches", @"-_getBlockStart:end:contentsEnd:forRange:stopAtLineSeparators:", @"-_getBracketedStringFromBuffer:string:", @"-_getBytesAsData:maxLength:usedLength:encoding:options:range:remainingRange:", @"-_getCString:maxLength:encoding:", @"-_getCharactersAsStringInRange:", @"-_initWithBytesOfUnknownEncoding:length:copy:usedEncoding:", @"-_initWithDataOfUnknownEncoding:", @"-_isCString", @"-_matchesCharacter:", @"-_newSubstringWithRange:zone:", @"-_rangeOfRegularExpressionPattern:options:range:locale:", @"-_scriptingAlternativeValueRankWithDescriptor:", @"-_scriptingTextDescriptor", @"-_smallestEncodingInCFStringEncoding", @"-_stringByReplacingOccurrencesOfRegularExpressionPattern:withTemplate:options:range:", @"-_stringByResolvingSymlinksInPathUsingCache:", @"-_stringByStandardizingPathUsingCache:", @"-_stringRepresentation", @"-_web_HTTPStyleLanguageCode", @"-_web_HTTPStyleLanguageCodeWithoutRegion", @"-_web_URLFragment", @"-_web_characterSetFromContentTypeHeader_nowarn", @"-_web_countOfString:", @"-_web_domainFromHost", @"-_web_domainMatches:", @"-_web_extractFourCharCode", @"-_web_fileNameFromContentDispositionHeader_nowarn", @"-_web_filenameByFixingIllegalCharacters", @"-_web_fixedCarbonPOSIXPath", @"-_web_hasCaseInsensitivePrefix:", @"-_web_hasCountryCodeTLD", @"-_web_isCaseInsensitiveEqualToString:", @"-_web_isFileURL", @"-_web_isJavaScriptURL", @"-_web_looksLikeAbsoluteURL", @"-_web_looksLikeIPAddress", @"-_web_mimeTypeFromContentTypeHeader_nowarn", @"-_web_parseAsKeyValuePairHandleQuotes_nowarn:", @"-_web_parseAsKeyValuePair_nowarn", @"-_web_rangeOfURLHost", @"-_web_rangeOfURLResourceSpecifier_nowarn", @"-_web_rangeOfURLScheme_nowarn", @"-_web_rangeOfURLUserPasswordHostPort", @"-_web_splitAtNonDateCommas_nowarn", @"-_web_stringByCollapsingNonPrintingCharacters", @"-_web_stringByExpandingTildeInPath", @"-_web_stringByReplacingValidPercentEscapes_nowarn", @"-_web_stringByTrimmingWhitespace", @"NSObject", @"-addObject:toBothSidesOfRelationshipWithKey:", @"-addObject:toPropertyWithKey:", @"-addObserver:forKeyPath:options:context:", @"-allPropertyKeys", @"-allowsWeakReference", @"-attributeKeys", @"-autoContentAccessingProxy", @"-autorelease", @"-awakeAfterUsingCoder:", @"-class", @"-classCode", @"-classDescription", @"-classDescriptionForDestinationKey:", @"-classForArchiver", @"-classForCoder", @"-classForKeyedArchiver", @"-classForPortCoder", @"-className", @"-clearProperties", @"-coerceValue:forKey:", @"-coerceValueForScriptingProperties:", @"-conformsToProtocol:", @"-copy", @"-copyScriptingValue:forKey:withProperties:", @"-createKeyValueBindingForKey:typeMask:", @"-dealloc", @"-debugDescription", @"-description", @"-description", @"-dictionaryWithValuesForKeys:", @"-didChange:valuesAtIndexes:forKey:", @"-didChangeValueForKey:", @"-didChangeValueForKey:withSetMutation:usingObjects:", @"-doesContain:", @"-doesNotRecognizeSelector:", @"-doesNotRecognizeSelector:", @"-entityName", @"-finalize", @"-flushKeyBindings", @"-forwardInvocation:", @"-forwardingTargetForSelector:", @"-handleQueryWithUnboundKey:", @"-handleTakeValue:forUnboundKey:", @"-hash", @"-implementsSelector:", @"-init", @"-insertValue:atIndex:inPropertyWithKey:", @"-insertValue:inPropertyWithKey:", @"-inverseForRelationshipKey:", @"-isCaseInsensitiveLike:", @"-isEqual:", @"-isEqualTo:", @"-isFault", @"-isGreaterThan:", @"-isGreaterThanOrEqualTo:", @"-isKindOfClass:", @"-isLessThan:", @"-isLessThanOrEqualTo:", @"-isLike:", @"-isMemberOfClass:", @"-isNSArray__", @"-isNSData__", @"-isNSDate__", @"-isNSDictionary__", @"-isNSNumber__", @"-isNSOrderedSet__", @"-isNSSet__", @"-isNSString__", @"-isNSTimeZone__", @"-isNSValue__", @"-isNotEqualTo:", @"-isProxy", @"-isToManyKey:", @"-keyValueBindingForKey:typeMask:", @"-methodDescriptionForSelector:", @"-methodForSelector:", @"-methodSignatureForSelector:", @"-methodSignatureForSelector:", @"-mutableArrayValueForKey:", @"-mutableArrayValueForKeyPath:", @"-mutableCopy", @"-mutableOrderedSetValueForKey:", @"-mutableOrderedSetValueForKeyPath:", @"-mutableSetValueForKey:", @"-mutableSetValueForKeyPath:", @"-newScriptingObjectOfClass:forValueForKey:withContentsValue:properties:", @"-objectSpecifier", @"-observationInfo", @"-observeValueForKeyPath:ofObject:change:context:", @"-ownsDestinationObjectsForRelationshipKey:", @"-performSelector:", @"-performSelector:object:afterDelay:", @"-performSelector:onThread:withObject:waitUntilDone:", @"-performSelector:onThread:withObject:waitUntilDone:modes:", @"-performSelector:withObject:", @"-performSelector:withObject:afterDelay:", @"-performSelector:withObject:afterDelay:inModes:", @"-performSelector:withObject:withObject:", @"-performSelectorInBackground:withObject:", @"-performSelectorOnMainThread:withObject:waitUntilDone:", @"-performSelectorOnMainThread:withObject:waitUntilDone:modes:", @"-release", @"-removeObject:fromBothSidesOfRelationshipWithKey:", @"-removeObject:fromPropertyWithKey:", @"-removeObserver:forKeyPath:", @"-removeObserver:forKeyPath:context:", @"-removeValueAtIndex:fromPropertyWithKey:", @"-replaceValueAtIndex:inPropertyWithKey:withValue:", @"-replacementObjectForArchiver:", @"-replacementObjectForCoder:", @"-replacementObjectForKeyedArchiver:", @"-replacementObjectForPortCoder:", @"-respondsToSelector:", @"-retain", @"-retainCount", @"-retainWeakReference", @"-scriptingProperties", @"-scriptingValueForSpecifier:", @"-self", @"-setNilValueForKey:", @"-setObservationInfo:", @"-setScriptingProperties:", @"-setValue:forKey:", @"-setValue:forKeyPath:", @"-setValue:forUndefinedKey:", @"-setValuesForKeysWithDictionary:", @"-storedValueForKey:", @"-superclass", @"-takeStoredValue:forKey:", @"-takeStoredValuesFromDictionary:", @"-takeValue:forKey:", @"-takeValue:forKeyPath:", @"-takeValuesFromDictionary:", @"-toManyRelationshipKeys", @"-toOneRelationshipKeys", @"-unableToSetNilForKey:", @"-validateTakeValue:forKeyPath:", @"-validateValue:forKey:", @"-validateValue:forKey:error:", @"-validateValue:forKeyPath:error:", @"-valueAtIndex:inPropertyWithKey:", @"-valueForKey:", @"-valueForKeyPath:", @"-valueForUndefinedKey:", @"-valueWithName:inPropertyWithKey:", @"-valueWithUniqueID:inPropertyWithKey:", @"-valuesForKeys:", @"-willChange:valuesAtIndexes:forKey:", @"-willChangeValueForKey:", @"-willChangeValueForKey:withSetMutation:usingObjects:", @"-zone", @"-___tryRetain_OA", @"-__autorelease_OA", @"-__dealloc_zombie", @"-__release_OA", @"-__retain_OA", @"-_addObserver:forProperty:options:context:", @"-_allowsDirectEncoding", @"-_asScriptTerminologyNameArray", @"-_asScriptTerminologyNameString", @"-_cfTypeID", @"-_changeValueForKey:key:key:usingBlock:", @"-_changeValueForKey:usingBlock:", @"-_compatibility_takeValue:forKey:", @"-_conformsToProtocolNamed:", @"-_copyDescription", @"-_createKeyValueBindingForKey:name:bindingType:", @"-_didChangeValuesForKeys:", @"-_implicitObservationInfo", @"-_isDeallocating", @"-_isKVOA", @"-_localClassNameForClass", @"-_notifyObserversForKeyPath:change:", @"-_oldValueForKey:", @"-_oldValueForKeyPath:", @"-_removeObserver:forProperty:", @"-_scriptingAddObjectsFromArray:toValueForKey:", @"-_scriptingAddObjectsFromSet:toValueForKey:", @"-_scriptingAddToReceiversArray:", @"-_scriptingAlternativeValueRankWithDescriptor:", @"-_scriptingArrayOfObjectsForSpecifier:", @"-_scriptingCanAddObjectsToValueForKey:", @"-_scriptingCanHandleCommand:", @"-_scriptingCanInsertBeforeOrReplaceObjectsAtIndexes:inValueForKey:", @"-_scriptingCanSetValue:forSpecifier:", @"-_scriptingCoerceValue:forKey:", @"-_scriptingCopyWithProperties:forValueForKey:ofContainer:", @"-_scriptingCount", @"-_scriptingCountNonrecursively", @"-_scriptingCountOfValueForKey:", @"-_scriptingDebugDescription", @"-_scriptingDescriptorOfComplexType:orReasonWhyNot:", @"-_scriptingDescriptorOfEnumeratorType:orReasonWhyNot:", @"-_scriptingDescriptorOfObjectType:orReasonWhyNot:", @"-_scriptingDescriptorOfValueType:orReasonWhyNot:", @"-_scriptingExists", @"-_scriptingIndexOfObjectForSpecifier:", @"-_scriptingIndexOfObjectWithName:inValueForKey:", @"-_scriptingIndexOfObjectWithUniqueID:inValueForKey:", @"-_scriptingIndexesOfObjectsForSpecifier:", @"-_scriptingIndicesOfObjectsAfterValidatingSpecifier:", @"-_scriptingIndicesOfObjectsForSpecifier:count:", @"-_scriptingInsertObject:inValueForKey:", @"-_scriptingInsertObjects:atIndexes:inValueForKey:", @"-_scriptingMightHandleCommand:", @"-_scriptingObjectAtIndex:inValueForKey:", @"-_scriptingObjectCountInValueForKey:", @"-_scriptingObjectForSpecifier:", @"-_scriptingObjectWithName:inValueForKey:", @"-_scriptingObjectWithUniqueID:inValueForKey:", @"-_scriptingObjectsAtIndexes:inValueForKey:", @"-_scriptingRemoveAllObjectsFromValueForKey:", @"-_scriptingRemoveObjectsAtIndexes:fromValueForKey:", @"-_scriptingRemoveValueForSpecifier:", @"-_scriptingReplaceObjectAtIndex:withObjects:inValueForKey:", @"-_scriptingSetOfObjectsForSpecifier:", @"-_scriptingSetValue:forKey:", @"-_scriptingSetValue:forSpecifier:", @"-_scriptingShouldCheckObjectIndexes", @"-_scriptingValueForKey:", @"-_scriptingValueForSpecifier:", @"-_setObject:forBothSidesOfRelationshipWithKey:", @"-_supportsGetValueWithNameForKey:perhapsByOverridingClass:", @"-_supportsGetValueWithUniqueIDForKey:perhapsByOverridingClass:", @"-_tryRetain", @"-_willChangeValuesForKeys:"];

  XCTAssertEqualObjects(components, expectedComponents);
}

- (void)testListingObjectMethodsWithoutIncludingAncestors
{
  self.object = @"test";

  [KKMethodCallLogger listMethodsForClass:[self.object class]];

  NSArray *components = [[sLogString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
  NSArray *expectedComponents = @[@"__NSCFConstantString", @"-autorelease", @"-copyWithZone:", @"-release", @"-retain", @"-retainCount"];

  XCTAssertEqualObjects(components, expectedComponents);
}

- (void)testTurningOffLoggingForAllObjects
{
  id obj1 = [NSObject new];
  id obj2 = [NSObject new];

  [KKMethodCallLogger startLoggingMethodCallsForObject:obj1];
  [KKMethodCallLogger startLoggingMethodCallsForObject:obj2];
  [KKMethodCallLogger stopLoggingMethodCallsForAllObjects];

  [obj1 isEqual:obj2];
  [obj1 hash];
  [obj2 hash];
  [obj2 isProxy];

  XCTAssertEqualObjects(sLogString, @"");
}

- (void)testListingLoggedObjects
{
  id array = [NSMutableArray array];
  id set = [NSMutableSet set];
  id obj = [NSObject new];

  [KKMethodCallLogger startLoggingMethodCallsForObject:array];
  [KKMethodCallLogger startLoggingMethodCallsForObject:set withName:@"self.mutableSet"];
  [KKMethodCallLogger startLoggingMethodCallsForObject:obj];
  [KKMethodCallLogger listLoggedObjects];

  NSString *expectedString = [NSString stringWithFormat:@"<__NSArrayM: %p>\n<__NSSetM: %p> self.mutableSet\n<NSObject: %p>\n\n", array, set, obj];
  XCTAssertEqualObjects(sLogString, expectedString);
}

- (void)testRetrievingLoggedObjects
{
  id obj1 = [NSObject new];
  id obj2 = [NSObject new];

  [KKMethodCallLogger startLoggingMethodCallsForObject:obj1];
  [KKMethodCallLogger startLoggingMethodCallsForObject:obj2];

  XCTAssertEqualObjects([KKMethodCallLogger loggedObjects], ([@[obj1, obj2] mutableCopy]));
}

- (void)testIgnoringClasses
{
  [KKMethodCallLogger startLoggingMethodCallsForObject:[NSArray class]];

  XCTAssertEqualObjects([KKMethodCallLogger loggedObjects], @[]);
  XCTAssertEqualObjects(sLogString, @"KKMethodCallLogger doesn't currently support logging class method calls.\n");
}

- (void)testNSObjectProtocolMethods
{
  self.object = [NSMutableArray array];

  BOOL objectIsKindOfClassMutableArray = [self.object isKindOfClass:[NSMutableArray class]];
  BOOL objectIsMemberOfClassArrayM = [self.object isMemberOfClass:NSClassFromString(@"__NSArrayM")];
  BOOL objectRespondsToAddObject = [self.object respondsToSelector:@selector(addObject:)];
  BOOL objectConformsToFastEnumeration = [self.object conformsToProtocol:@protocol(NSFastEnumeration)];
  BOOL objectIsEqualToEmptyArray = [self.object isEqual:@[]];
  NSUInteger objectHash = [self.object hash];
  NSString *objectDescription = [self.object description];
  NSString *objectDebugDescription = [self.object debugDescription];
  Class objectClass = [self.object class];
  Class objectSuperclass = [self.object superclass];

  [KKMethodCallLogger startLoggingMethodCallsForObject:self.object];

  XCTAssertEqual([self.object isKindOfClass:[NSMutableArray class]], objectIsKindOfClassMutableArray);
  XCTAssertEqual([self.object isMemberOfClass:NSClassFromString(@"__NSArrayM")], objectIsMemberOfClassArrayM);
  XCTAssertEqual([self.object respondsToSelector:@selector(addObject:)], objectRespondsToAddObject);
  XCTAssertEqual([self.object conformsToProtocol:@protocol(NSFastEnumeration)], objectConformsToFastEnumeration);
  XCTAssertEqual([self.object isEqual:@[]], objectIsEqualToEmptyArray);
  XCTAssertEqual([self.object hash], objectHash);
  XCTAssertEqualObjects([self.object description], objectDescription);
  XCTAssertEqualObjects([self.object debugDescription], objectDebugDescription);
  XCTAssertEqualObjects([self.object class], objectClass);
  XCTAssertEqualObjects([self.object superclass], objectSuperclass);
}

- (void)testNotLoggingNilObject
{
  self.object = nil;

  [KKMethodCallLogger startLoggingMethodCallsForObject:self.object];

  XCTAssertEqualObjects([KKMethodCallLogger loggedObjects], @[]);
  XCTAssertEqualObjects(sLogString, @"KKMethodCallLogger cannot log calls for a nil object.\n");
}

- (void)testImmortalObjectsNotGettingReleased
{
  __weak id weakString = @"test";

  [KKMethodCallLogger startLoggingMethodCallsForObject:weakString];
  [KKMethodCallLogger stopLoggingMethodCallsForObject:weakString];

  XCTAssertNotNil(weakString);
}

- (void)testLoggedObjectsWorkingCorrectly
{
  NSMutableArray *array = [NSMutableArray array];

  [KKMethodCallLogger startLoggingMethodCallsForObject:array];

  [array addObject:@(1)];
  [array addObjectsFromArray:@[@(2), @(3)]];

  [KKMethodCallLogger stopLoggingMethodCallsForObject:array];

  [array removeObject:@(2)];

  XCTAssertEqualObjects(array, (@[@(1), @(3)]));
}

#pragma mark - Log Function

void LogFunction(NSString *format, ...)
{
  va_list arguments;
  va_start(arguments, format);

  [sLogString appendString:[[NSString alloc] initWithFormat:format arguments:arguments]];
  [sLogString appendString:@"\n"];

  va_end(arguments);
}

@end
