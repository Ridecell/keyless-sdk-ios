//
//  TokenTransformerTests.swift
//  Keyless_Tests
//
//  Created by Marc Maguire on 2019-11-10.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import Keyless

class TokenTransformerTests: XCTestCase {

    var sut: TokenTransformer!
    var validToken: String!
    var invalidToken: String!
    
    
    override func setUp() {
        self.sut = DefaultKeylessTokenTransformer()
        self.validToken = "CiQwNTc0NTgzQi0wRDhELTI5NjItNEQ3OS0wRjQzRUVCOTZDOTgStAxNSUlFb3dJQkFBS0NBUUVBa0pxdklpMUtDb2N2SEpVKzFpNzV5TCtVVDJqaTl5YTdMa01nNUVkZzdLMTVpMFJwYkx1TlJiV2xDMk1kZVArRWxjMUtPSEcycEFHd3VhYi9qU2ZUQ2lFNWhMWHo5QjQwQTAwRUE0enRmV1RuRVhvZGEzUWRSZzAzNWlJbjdGWi9oZmNjUFFyT1BEMkJXZi9wRnN3SGFNSHJGNjFpUFhsOTRMZi9DWjNIRWVvM2d4TytqS0dPT1A4Yk1CUGIraEpnZHFxY1hrWDc4ZHNaeVZNSzZJREs0T2ZqeVljK1FMSTAyQzhITzhsbFhmYXY2cjFYOXZ0cCsvZzNaNHpDSFRxZTFhdnhpSGN5c05nRzQvOG5ISmg0ZHBRa1lLVERFTHpQWFUxeXBHUVlnVHV0dng3aVd6UnlZa1QwQWVOOGZ4dXpxbURTd3FvZWNRQmZMRnRSak9XWFRRSURBUUFCQW9JQkFBUFF1UUhrclFQd2JpdEp1c3lKbFJpWlhzU1E4V1Z4QUZaU1QyOWIwaHNITnJlWWVLbWdSelFlMGZuUXhkUjM5WEVZWjJGc05WUHl6Q0s4aDhORjJPUE1YWjZsU0YydXRhanlvc0pQT1JnL3VIaGdhWjlPQXltMzFwRG10M2xIdDZTbFprN1dxL3RiUDJyMi9XNUJ1RE9vNDRHT2x4TFAwNlRzRUk3RWtCM21XYm4yWjBVMVNva2JnOGJtSzlpWGJBZ3czUW9VSEtOc1FpalZvMExZaHBjQ045QTE5Wm5yM0NYdjEzZUhPRjBpSWFjMzZxRU5wRDRhRTZRYkplWW5jWWhTajlwOHNQVmF4eHptRVNUMjhvamxOVFRlck5UMGxyRTMwWXVUQ01NM2hHL3Y0UGI5RDJGaVlaQ1pjcytWN3pBcTRYeHBZQ2lUNmd3TlE0NXRNM2NDZ1lFQTJ2dTNSdFFNT3FSTDZjaWg2dnZFWjA5YTdrZzBzbjJybXVaVFhTN2F6STV3UXVIQVFSOWRsbkljbTFEblNPcXpGMk9yM0VoaDljYXJEbXVXUlRjU2dXSHpsY2cydW1rSTBSTTBLdUJwU1pleDZvbG9ESWUzREE0bCs2cWU4RG50Wk5DOFBTeEdubVhKV0VnMDBydm1QMHUwbWFCVVd0YzZldytBQm1rcDhwTUNnWUVBcVF4S0RPL2xGcC9yWlBaWUM4YWZtb0ptcXR6R2NPMmdBQVUwQmkrNVJoN1RzUWRMdmVnWFNyVWhsZ2drK0l1ckE2LzM5NmIxcE9lYVZNM2FOYjNwTVEzQUZJaFZGTTljcG9Eazc4dGJwYURxRHJLcGY2T3UxamJHSWlqdnVIMVo3dVprcnVBZFJiSU14dThBbUs2OTZobzNCVE12QTdBUmM0Q2VwdG9YR3A4Q2dZQllDQjBUb2ljUVpBQUlpWmxlQjd4YTg3SFFYTUtpaHBhMy9LUENzQlZSYW1tQzJaSWFHK3Zaa1NJaTVoRTBaUFYrRDVtRlFxdnV5K0QwT1JmOTF6ZmZQMnRXNlZmbTlGYVJCakZRazBxQVJUVkczZG93UDFhOHgrdEpFcncyUW5OR3Rnc1daSGczTVNBU0YyVDAyb2lqSldJQzZFdEJBWWtHODZJNThZamxkUUtCZ0ducjhWbzUxbWxldXJnQVF4cmQwWk9Xc1kzTjErbGFleTZJRkJqc1BrTFpmZnNtZnliM0RlRVpyWG04a0szTGxkUXhwa1hlcjN3c1FsOXd2SkYvOVdWdklETzlXTkk1Tyt4NFJ2cVppVXMya0hHMU1NOXhXRk9RN29UbzhZdS92MklacW15SXNNN0N5WTY4b3JzSWdxYjAxaFRFQldsaUlRMG1Ra0o1MUpBeEFvR0JBS2RyNXBBRHR6N0ZJL25mQmUrV0h0K1U5SE5pZmJPT1dJT3RVZEsvM3p6bHBNckpXMWNhUm15c0RmTTNiYXhlcGxVUTV0Y0xQUFNmTXpIZEY4RHB2OGJpUTdublFpQkpmdmljQlZEdzJaUzlGQ2Jod3hmN2JtdmkweTVEbEh6blVLMHdOelNHTE5QYnJpK09wTXQ0QldxaG1mNkZURnBBMkQ3blpGeGJ4elBjGiDZet962AOA+1EBw27oR/+wUzmrJvwZL0lvzI3AhJbuICIgTNTGoJ5tkF3LPgZa+rMYDO+o5teQVJRVDkdh2thqXwcq4wIKgQIAkJqvIi1KCocvHJU+1i75yL+UT2ji9ya7LkMg5Edg7K15i0RpbLuNRbWlC2MdeP+Elc1KOHG2pAGwuab/jSfTCiE5hLXz9B40A00EA4ztfWTnEXoda3QdRg035iIn7FZ/hfccPQrOPD2BWf/pFswHaMHrF61iPXl94Lf/CZ3HEeo3gxO+jKGOOP8bMBPb+hJgdqqcXkX78dsZyVMK6IDK4OfjyYc+QLI02C8HO8llXfav6r1X9vtp+/g3Z4zCHTqe1avxiHcysNgG4/8nHJh4dpQkYKTDELzPXU1ypGQYgTutvx7iWzRyYkT0AeN8fxuzqmDSwqoecQBfLFtRjOWXTRDom92pzi4aEJEWm/9V0kRDu/gym4dYO0MgnYeMiAIqDQiMqdSSAhIFDf8PAAAwyJTIwtgtOMikpqnOLkCEB0iEB1IbCgUNPwAAABIKDQAAgEAVAADgQBj0AyUAAIA+MoACbn2pRcWilSk1Wp2uy2PsDraowYMGWdPDGkzFkKnY5AaDH6M6N+owdpayvkrDd3VKb8kmO0y7+o3gu58JMFmQgbrRwC0q8btxlxA5oBAqz8kQ+m1Ul9XDIXPRHmFSWw92v0a+xEd0vnDsBrl9e2IYOy2cZbQXtV4B3RTumkUAVauOqPRvODJO/lnrf6ukpIWDyML/SQkqzQv+Gk5/78mRCjY4DXDXLJ5DHPPv/RlD0/nDZ8zssUvMgwV4Qmc9XBPOMkQVKoigzkjrjNLPhf5I/rbN2dttqXTKkLvRlfA6cjZ7owRZ+SMWxXH4qqFdUmtvgJaBQZiPxUwMepqi7teirQ=="
        self.invalidToken = "INVALID_TOKEN"
    }

    override func tearDown() {
        self.sut = nil
        self.validToken = nil
        self.invalidToken = nil
    }

    func testTransformSucceedsWithValidToken() {
        do {
            let _ = try sut.transform(validToken)
            XCTAssert(true)
        } catch {
            XCTFail()
        }
    }
    
    func testTransformFailsWithDecodedInValidToken() {
        do {
            let _ = try sut.transform(invalidToken)
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }
    
    func testTransformFailsWithInValidToken() {
        let base64EncodedInvalidToken = "SU5WQUxJRF9UT0tFTg=="
        do {
            let _ = try sut.transform(base64EncodedInvalidToken)
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

}
