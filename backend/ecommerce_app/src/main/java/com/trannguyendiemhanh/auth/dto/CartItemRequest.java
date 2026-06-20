package com.trannguyendiemhanh.auth.dto;

import lombok.Data;

@Data
public class CartItemRequest {
    private String accountId;
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
}
