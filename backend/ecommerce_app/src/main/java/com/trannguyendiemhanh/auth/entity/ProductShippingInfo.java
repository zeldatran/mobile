package com.trannguyendiemhanh.auth.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "product_shipping_info")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductShippingInfo {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Product product;

    @Builder.Default
    @Column(nullable = false)
    private BigDecimal weight = BigDecimal.ZERO;

    @Column(name = "weight_unit", length = 10)
    private String weightUnit;

    @Builder.Default
    @Column(nullable = false)
    private BigDecimal volume = BigDecimal.ZERO;

    @Column(name = "volume_unit", length = 10)
    private String volumeUnit;

    @Builder.Default
    @Column(name = "dimension_width", nullable = false)
    private BigDecimal dimensionWidth = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "dimension_height", nullable = false)
    private BigDecimal dimensionHeight = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "dimension_depth", nullable = false)
    private BigDecimal dimensionDepth = BigDecimal.ZERO;

    @Column(name = "dimension_unit", length = 10)
    private String dimensionUnit;
}
