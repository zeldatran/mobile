package com.trannguyendiemhanh.auth.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class AuthResponse {
    private boolean success;
    private String message;
    private String token; // Optional JWT token
    private UserDto user;

    @Data
    @Builder
    public static class UserDto {
        private UUID id;
        private String firstName;
        private String lastName;
        private String email;
        private String phoneNumber;
        private String roleName;
    }
}
