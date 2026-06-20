package com.trannguyendiemhanh.auth.dto;

import com.trannguyendiemhanh.auth.entity.CardItem;
import lombok.Builder;
import lombok.Data;

import java.util.UUID;

@Data
@Builder
public class CartItemResponse {
    private UUID id;
    private UUID cardId;
    private String productKey;
    private String productName;
    private String brand;
    private String image;
    private Integer price;
    private Integer oldPrice;
    private Integer discountPercent;
    private Double rating;
    private Integer reviews;
    private String size;
    private String color;
    private Integer quantity;

    public static CartItemResponse fromEntity(CardItem item) {
        return CartItemResponse.builder()
                .id(item.getId())
                .cardId(item.getCard() == null ? null : item.getCard().getId())
                .productKey(item.getProductKey())
                .productName(item.getProductName())
                .brand(item.getBrand())
                .image(item.getImage())
                .price(item.getPrice())
                .oldPrice(item.getOldPrice())
                .discountPercent(item.getDiscountPercent())
                .rating(item.getRating())
                .reviews(item.getReviews())
                .size(item.getSize())
                .color(item.getColor())
                .quantity(item.getQuantity())
                .build();
    }
}
