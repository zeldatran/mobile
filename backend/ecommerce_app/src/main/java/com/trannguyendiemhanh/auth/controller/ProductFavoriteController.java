package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.ProductFavorite;
import com.trannguyendiemhanh.auth.service.ProductFavoriteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/favorites")
public class ProductFavoriteController {

    private final ProductFavoriteService productFavoriteService;

    @Autowired
    public ProductFavoriteController(ProductFavoriteService productFavoriteService) {
        this.productFavoriteService = productFavoriteService;
    }

    @GetMapping("/account/{accountId}")
    public ResponseEntity<List<ProductFavorite>> getFavorites(@PathVariable UUID accountId) {
        return ResponseEntity.ok(productFavoriteService.getFavorites(accountId));
    }

    @PostMapping
    public ResponseEntity<?> addFavorite(@RequestBody Map<String, Object> payload) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(productFavoriteService.addFavorite(payload));
        } catch (RuntimeException error) {
            return ResponseEntity.badRequest().body(Map.of("message", error.getMessage()));
        }
    }

    @DeleteMapping("/account/{accountId}/product/{productKey}")
    public ResponseEntity<Void> removeFavorite(
            @PathVariable UUID accountId,
            @PathVariable String productKey) {
        productFavoriteService.removeFavorite(accountId, productKey);
        return ResponseEntity.noContent().build();
    }
}
