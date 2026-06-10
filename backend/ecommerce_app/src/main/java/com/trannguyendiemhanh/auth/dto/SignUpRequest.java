package com.trannguyendiemhanh.auth.dto;

import lombok.Data;

@Data
public class SignUpRequest {
    private String name;
    private String firstName;
    private String lastName;
    private String phoneNumber;
    private String email;
    private String password;
    private String image;
    private String placeholder;
}
