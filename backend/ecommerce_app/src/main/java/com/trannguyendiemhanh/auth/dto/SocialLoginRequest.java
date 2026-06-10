package com.trannguyendiemhanh.auth.dto;

import lombok.Data;

@Data
public class SocialLoginRequest {
    private String provider; // "google" or "facebook"
    private String token;    // idToken for google, accessToken for facebook
    private boolean signUp;  // true if we want to register a new account if it doesn't exist
}
