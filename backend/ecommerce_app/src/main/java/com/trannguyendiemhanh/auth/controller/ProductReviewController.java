package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.ProductReview;
import com.trannguyendiemhanh.auth.service.ProductReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/reviews")
public class ProductReviewController {

    private final ProductReviewService productReviewService;

    @Autowired
    public ProductReviewController(ProductReviewService productReviewService) {
        this.productReviewService = productReviewService;
    }

    @GetMapping("/product/{productKey}")
    public ResponseEntity<List<ProductReview>> getReviews(@PathVariable String productKey) {
        return ResponseEntity.ok(productReviewService.getReviews(productKey));
    }

    @GetMapping("/product/{productKey}/summary")
    public ResponseEntity<Map<String, Object>> getSummary(
            @PathVariable String productKey,
            @RequestParam(required = false) UUID accountId) {
        return ResponseEntity.ok(productReviewService.getSummary(productKey, accountId));
    }

    @PostMapping
    public ResponseEntity<?> createReview(@RequestBody Map<String, Object> payload) {
        try {
            ProductReview review = productReviewService.createReview(
                    (String) payload.get("productKey"),
                    (String) payload.get("productName"),
                    UUID.fromString((String) payload.get("accountId")),
                    (Integer) payload.get("rating"),
                    (String) payload.get("comment"),
                    (List<String>) payload.getOrDefault("photoUrls", List.of())
            );
            return ResponseEntity.status(HttpStatus.CREATED).body(review);
        } catch (RuntimeException error) {
            return ResponseEntity.badRequest().body(Map.of("message", error.getMessage()));
        }
    }

    @PostMapping(value = "/photos", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> uploadPhoto(@RequestParam("file") MultipartFile file) {
        try {
            String url = productReviewService.uploadPhoto(file);
            return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("url", url));
        } catch (IOException | RuntimeException error) {
            return ResponseEntity.badRequest().body(Map.of("message", error.getMessage()));
        }
    }
}
