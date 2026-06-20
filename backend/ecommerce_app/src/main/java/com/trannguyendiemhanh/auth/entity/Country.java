package com.trannguyendiemhanh.auth.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "countries")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Country {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, length = 2)
    private String iso;

    @Column(nullable = false, length = 80)
    private String name;

    @Column(name = "upper_name", nullable = false, length = 80)
    private String upperName;

    @Column(length = 3)
    private String iso3;

    @Column(name = "num_code")
    private Integer numCode;

    @Column(name = "phone_code", nullable = false)
    private Integer phoneCode;
}
