package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.dto.CartItemRequest;
import com.trannguyendiemhanh.auth.dto.CartItemResponse;
import com.trannguyendiemhanh.auth.service.CardItemService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/cart")
public class CartController {
    private final CardItemService cardItemService;

    public CartController(CardItemService cardItemService) {
        this.cardItemService = cardItemService;
    }

    @PostMapping("/items")
    public ResponseEntity<CartItemResponse> addToCart(@RequestBody CartItemRequest request) {
        return ResponseEntity.ok(cardItemService.addToCart(request));
    }

    @GetMapping("/account/{accountId}")
    public ResponseEntity<List<CartItemResponse>> getCartItems(@PathVariable UUID accountId) {
        return ResponseEntity.ok(cardItemService.getCartItems(accountId));
    }
}
