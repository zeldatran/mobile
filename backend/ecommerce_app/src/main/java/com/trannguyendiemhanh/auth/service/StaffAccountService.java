package com.trannguyendiemhanh.auth.service;

import java.util.UUID;

import com.trannguyendiemhanh.auth.dto.*;
import com.trannguyendiemhanh.auth.entity.StaffAccount;

public interface StaffAccountService {
    AuthResponse register(SignUpRequest request);
    AuthResponse login(AuthRequest request);
    AuthResponse socialLogin(SocialLoginRequest request);
    AuthResponse changePassword(UUID accountId, String currentPassword, String newPassword);
    StaffAccount getAccountById(UUID id);
}
