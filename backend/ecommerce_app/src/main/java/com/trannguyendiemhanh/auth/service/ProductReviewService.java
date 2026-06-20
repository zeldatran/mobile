package com.trannguyendiemhanh.auth.service;

import com.trannguyendiemhanh.auth.entity.ProductReview;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface ProductReviewService {
    List<ProductReview> getReviews(String productKey);

    Map<String, Object> getSummary(String productKey, UUID accountId);

    ProductReview createReview(
            String productKey,
            String productName,
            UUID accountId,
            Integer rating,
            String comment,
            List<String> photoUrls);

    String uploadPhoto(MultipartFile file) throws IOException;
}
