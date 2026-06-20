package com.trannguyendiemhanh.auth.service;

import com.trannguyendiemhanh.auth.dto.CartItemRequest;
import com.trannguyendiemhanh.auth.dto.CartItemResponse;
import com.trannguyendiemhanh.auth.entity.CardItem;

import java.util.List;
import java.util.UUID;

public interface CardItemService extends CrudService<CardItem, UUID> {
    CartItemResponse addToCart(CartItemRequest request);

    List<CartItemResponse> getCartItems(UUID accountId);
}
