package com.trannguyendiemhanh.auth.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "shipping_rates")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShippingRate {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shipping_zone_id", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private ShippingZone shippingZone;

    @Column(name = "weight_unit", length = 10)
    private String weightUnit;

    @Builder.Default
    @Column(name = "min_value", nullable = false)
    private BigDecimal minValue = BigDecimal.ZERO;

    @Column(name = "max_value")
    private BigDecimal maxValue;

    @Builder.Default
    @Column(name = "no_max", nullable = false)
    private Boolean noMax = true;

    @Builder.Default
    @Column(nullable = false)
    private BigDecimal price = BigDecimal.ZERO;
}
