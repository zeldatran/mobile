package com.trannguyendiemhanh.auth.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "card_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CardItem {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "card_id")
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Card card;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Product product;

    @Column(name = "product_key", length = 255)
    private String productKey;

    @Column(name = "product_name", length = 255)
    private String productName;

    @Column(length = 255)
    private String brand;

    @Column(columnDefinition = "TEXT")
    private String image;

    private Integer price;

    @Column(name = "old_price")
    private Integer oldPrice;

    @Column(name = "discount_percent")
    private Integer discountPercent;

    private Double rating;

    private Integer reviews;

    @Column(length = 24)
    private String size;

    @Column(length = 40)
    private String color;

    @Builder.Default
    private Integer quantity = 1;
}
