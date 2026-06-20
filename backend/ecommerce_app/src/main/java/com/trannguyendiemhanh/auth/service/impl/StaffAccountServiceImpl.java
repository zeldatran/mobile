package com.trannguyendiemhanh.auth.service.impl;

import lombok.Getter;
import lombok.Setter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.trannguyendiemhanh.auth.dto.*;
import com.trannguyendiemhanh.auth.entity.Role;
import com.trannguyendiemhanh.auth.entity.StaffAccount;
import com.trannguyendiemhanh.auth.repository.RoleRepository;
import com.trannguyendiemhanh.auth.repository.StaffAccountRepository;
import com.trannguyendiemhanh.auth.service.StaffAccountService;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class StaffAccountServiceImpl implements StaffAccountService {

    private final StaffAccountRepository staffAccountRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final RestTemplate restTemplate;

    @Autowired
    public StaffAccountServiceImpl(StaffAccountRepository staffAccountRepository,
            RoleRepository roleRepository,
            PasswordEncoder passwordEncoder,
            RestTemplate restTemplate) {
        this.staffAccountRepository = staffAccountRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
        this.restTemplate = restTemplate;
    }

    @Override
    public AuthResponse register(SignUpRequest request) {
        if (staffAccountRepository.existsByEmail(request.getEmail())) {
            return AuthResponse.builder()
                    .success(false)
                    .message("EMAIL_ALREADY_EXISTS")
                    .build();
        }

        // Try to fetch a default role or assign NULL if none exists
        Role defaultRole = roleRepository.findByRoleName("STAFF")
                .orElseGet(() -> roleRepository.findByRoleName("USER")
                        .orElse(null));

        String firstName = request.getFirstName();
        String lastName = request.getLastName();

        if ((firstName == null || firstName.isBlank()) && request.getName() != null && !request.getName().isBlank()) {
            String[] nameParts = request.getName().trim().split("\\s+", 2);
            firstName = nameParts[0];
            lastName = nameParts.length > 1 ? nameParts[1] : "";
        }

        StaffAccount account = StaffAccount.builder()
                .firstName(firstName)
                .lastName(lastName)
                .phoneNumber(request.getPhoneNumber())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(defaultRole)
                .active(true)
                .image(request.getImage())
                .placeholder(request.getPlaceholder())
                .build();

        StaffAccount savedAccount = staffAccountRepository.save(account);

        return AuthResponse.builder()
                .success(true)
                .message("REGISTRATION_SUCCESSFUL")
                .user(mapToUserDto(savedAccount))
                .build();
    }

    @Override
    public AuthResponse login(AuthRequest request) {
        Optional<StaffAccount> accountOpt = staffAccountRepository.findByEmail(request.getEmail());

        if (accountOpt.isEmpty()) {
            return AuthResponse.builder()
                    .success(false)
                    .message("USER_NOT_FOUND")
                    .build();
        }

        StaffAccount account = accountOpt.get();

        if (!passwordEncoder.matches(request.getPassword(), account.getPasswordHash())) {
            return AuthResponse.builder()
                    .success(false)
                    .message("INVALID_CREDENTIALS")
                    .build();
        }

        if (!account.getActive()) {
            return AuthResponse.builder()
                    .success(false)
                    .message("ACCOUNT_INACTIVE")
                    .build();
        }

        return AuthResponse.builder()
                .success(true)
                .message("LOGIN_SUCCESSFUL")
                .token("mock-jwt-token-" + UUID.randomUUID())
                .user(mapToUserDto(account))
                .build();
    }

    @Override
    public AuthResponse socialLogin(SocialLoginRequest request) {
        SocialProfile profile;
        try {
            profile = profileFromRequest(request);
            if (profile == null && "google".equalsIgnoreCase(request.getProvider())) {
                profile = verifyGoogleToken(request.getToken());
            } else if (profile == null && "facebook".equalsIgnoreCase(request.getProvider())) {
                profile = verifyFacebookToken(request.getToken());
            } else if (profile == null) {
                return AuthResponse.builder()
                        .success(false)
                        .message("INVALID_PROVIDER")
                        .build();
            }
        } catch (Exception e) {
            return AuthResponse.builder()
                    .success(false)
                    .message("SOCIAL_AUTH_FAILED: " + e.getMessage())
                    .build();
        }

        Optional<StaffAccount> accountOpt = staffAccountRepository.findByEmail(profile.getEmail());

        if (accountOpt.isEmpty()) {
            if (request.isSignUp()) {
                // Auto-register social user
                Role defaultRole = roleRepository.findByRoleName("STAFF")
                        .orElseGet(() -> roleRepository.findByRoleName("USER")
                                .orElse(null));

                StaffAccount account = StaffAccount.builder()
                        .firstName(profile.getFirstName() != null && !profile.getFirstName().isEmpty() ? profile.getFirstName() : "Social")
                        .lastName(profile.getLastName() != null && !profile.getLastName().isEmpty() ? profile.getLastName() : "User")
                        .email(profile.getEmail())
                        .passwordHash(passwordEncoder.encode(UUID.randomUUID().toString())) // Secure random password
                        .role(defaultRole)
                        .active(true)
                        .image(profile.getImage())
                        .build();

                StaffAccount savedAccount = staffAccountRepository.save(account);

                return AuthResponse.builder()
                        .success(true)
                        .message("REGISTRATION_SUCCESSFUL")
                        .user(mapToUserDto(savedAccount))
                        .build();
            } else {
                // User does not exist, return USER_NOT_FOUND and pre-filled social info
                AuthResponse.UserDto userDto = AuthResponse.UserDto.builder()
                        .email(profile.getEmail())
                        .firstName(profile.getFirstName())
                        .lastName(profile.getLastName())
                        .build();

                return AuthResponse.builder()
                        .success(false)
                        .message("USER_NOT_FOUND")
                        .user(userDto)
                        .build();
            }
        }

        StaffAccount account = accountOpt.get();
        if (!account.getActive()) {
            return AuthResponse.builder()
                    .success(false)
                    .message("ACCOUNT_INACTIVE")
                    .build();
        }

        // Update profile picture if empty
        if (account.getImage() == null && profile.getImage() != null) {
            account.setImage(profile.getImage());
            staffAccountRepository.save(account);
        }

        return AuthResponse.builder()
                .success(true)
                .message("LOGIN_SUCCESSFUL")
                .token("mock-jwt-token-social-" + UUID.randomUUID())
                .user(mapToUserDto(account))
                .build();
    }

    @Override
    public StaffAccount getAccountById(UUID id) {
        return staffAccountRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Account not found with ID: " + id));
    }

    @Override
    public AuthResponse changePassword(UUID accountId, String currentPassword, String newPassword) {
        Optional<StaffAccount> accountOpt = staffAccountRepository.findById(accountId);
        if (accountOpt.isEmpty()) {
            return AuthResponse.builder()
                    .success(false)
                    .message("USER_NOT_FOUND")
                    .build();
        }

        if (newPassword == null || newPassword.length() < 6) {
            return AuthResponse.builder()
                    .success(false)
                    .message("PASSWORD_TOO_SHORT")
                    .build();
        }

        StaffAccount account = accountOpt.get();
        if (currentPassword == null || !passwordEncoder.matches(currentPassword, account.getPasswordHash())) {
            return AuthResponse.builder()
                    .success(false)
                    .message("INVALID_CURRENT_PASSWORD")
                    .build();
        }

        account.setPasswordHash(passwordEncoder.encode(newPassword));
        staffAccountRepository.save(account);

        return AuthResponse.builder()
                .success(true)
                .message("PASSWORD_CHANGED")
                .user(mapToUserDto(account))
                .build();
    }

    private AuthResponse.UserDto mapToUserDto(StaffAccount account) {
        return AuthResponse.UserDto.builder()
                .id(account.getId())
                .firstName(account.getFirstName())
                .lastName(account.getLastName())
                .email(account.getEmail())
                .phoneNumber(account.getPhoneNumber())
                .roleName(account.getRole() != null ? account.getRole().getRoleName() : null)
                .build();
    }

    private SocialProfile profileFromRequest(SocialLoginRequest request) {
        if (request.getEmail() == null || request.getEmail().trim().isEmpty()) {
            return null;
        }

        SocialProfile profile = new SocialProfile();
        profile.setEmail(request.getEmail().trim().toLowerCase());
        profile.setImage(request.getPhotoUrl());

        String name = request.getName() == null ? "" : request.getName().trim();
        if (name.isEmpty()) {
            profile.setFirstName("Social");
            profile.setLastName("User");
            return profile;
        }

        String[] nameParts = name.split("\\s+", 2);
        profile.setFirstName(nameParts[0]);
        profile.setLastName(nameParts.length > 1 ? nameParts[1] : "");
        return profile;
    }

    private SocialProfile verifyGoogleToken(String idToken) {
        String url = "https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken;
        try {
            Map<String, Object> response = restTemplate.getForObject(url, Map.class);
            if (response != null && response.containsKey("email")) {
                SocialProfile profile = new SocialProfile();
                profile.setEmail((String) response.get("email"));
                profile.setFirstName((String) response.get("given_name"));
                profile.setLastName((String) response.get("family_name"));
                profile.setImage((String) response.get("picture"));
                return profile;
            }
        } catch (Exception e) {
            throw new RuntimeException("Google token verification failed: " + e.getMessage());
        }
        throw new RuntimeException("Invalid Google token");
    }

    private SocialProfile verifyFacebookToken(String accessToken) {
        String url = "https://graph.facebook.com/me?fields=id,name,first_name,last_name,email,picture.type(large)&access_token="
                + accessToken;
        try {
            Map<String, Object> response = restTemplate.getForObject(url, Map.class);
            if (response != null) {
                SocialProfile profile = new SocialProfile();
                String email = (String) response.get("email");
                if (email == null || email.trim().isEmpty()) {
                    String id = (String) response.get("id");
                    email = "fb_" + id + "@facebook.com";
                }
                profile.setEmail(email);
                profile.setFirstName((String) response.get("first_name"));
                profile.setLastName((String) response.get("last_name"));

                if (response.containsKey("picture")) {
                    Map<String, Object> picture = (Map<String, Object>) response.get("picture");
                    if (picture.containsKey("data")) {
                        Map<String, Object> data = (Map<String, Object>) picture.get("data");
                        profile.setImage((String) data.get("url"));
                    }
                }
                return profile;
            }
        } catch (Exception e) {
            throw new RuntimeException("Facebook token verification failed: " + e.getMessage());
        }
        throw new RuntimeException("Invalid Facebook token");
    }

    @Getter
    @Setter
    private static class SocialProfile {
        private String email;
        private String firstName;
        private String lastName;
        private String image;
    }
}
