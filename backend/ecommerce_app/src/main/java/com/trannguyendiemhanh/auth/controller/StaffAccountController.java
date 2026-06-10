package com.trannguyendiemhanh.auth.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.trannguyendiemhanh.auth.dto.*;
import com.trannguyendiemhanh.auth.service.StaffAccountService;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class StaffAccountController {

    private final StaffAccountService staffAccountService;

    @Autowired
    public StaffAccountController(StaffAccountService staffAccountService) {
        this.staffAccountService = staffAccountService;
    }

    @PostMapping({"/register", "/signup"})
    public ResponseEntity<AuthResponse> register(@RequestBody SignUpRequest request) {
        AuthResponse response = staffAccountService.register(request);
        if (!response.isSuccess()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody AuthRequest request) {
        AuthResponse response = staffAccountService.login(request);
        if (!response.isSuccess()) {
            if ("USER_NOT_FOUND".equals(response.getMessage())) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
            }
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }
        return ResponseEntity.ok(response);
    }

    @PostMapping("/social-login")
    public ResponseEntity<AuthResponse> socialLogin(@RequestBody SocialLoginRequest request) {
        AuthResponse response = staffAccountService.socialLogin(request);
        if (!response.isSuccess()) {
            if ("USER_NOT_FOUND".equals(response.getMessage())) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
            }
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }
        return ResponseEntity.ok(response);
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        if (email == null || email.trim().isEmpty() || !email.contains("@")) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", "false",
                    "message", "INVALID_EMAIL"
            ));
        }
        // Mock password reset response
        return ResponseEntity.ok(Map.of(
                "success", "true",
                "message", "A password reset link has been sent to " + email
        ));
    }
}
