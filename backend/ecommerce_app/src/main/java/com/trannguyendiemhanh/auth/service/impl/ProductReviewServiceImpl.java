package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.ProductReview;
import com.trannguyendiemhanh.auth.entity.StaffAccount;
import com.trannguyendiemhanh.auth.repository.ProductReviewRepository;
import com.trannguyendiemhanh.auth.repository.StaffAccountRepository;
import com.trannguyendiemhanh.auth.service.ProductReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class ProductReviewServiceImpl implements ProductReviewService {

    private static final Path REVIEW_UPLOAD_DIR = Path.of("uploads", "reviews");

    private final ProductReviewRepository productReviewRepository;
    private final StaffAccountRepository staffAccountRepository;

    @Autowired
    public ProductReviewServiceImpl(
            ProductReviewRepository productReviewRepository,
            StaffAccountRepository staffAccountRepository) {
        this.productReviewRepository = productReviewRepository;
        this.staffAccountRepository = staffAccountRepository;
    }

    @Override
    public List<ProductReview> getReviews(String productKey) {
        return productReviewRepository.findByProductKeyOrderByCreatedAtDesc(productKey);
    }

    @Override
    public Map<String, Object> getSummary(String productKey, UUID accountId) {
        long count = productReviewRepository.countByProductKey(productKey);
        double average = productReviewRepository.averageRatingByProductKey(productKey);
        boolean reviewed = accountId != null
                && productReviewRepository.existsByProductKeyAndAccountId(productKey, accountId);

        return Map.of(
                "productKey", productKey,
                "count", count,
                "average", average,
                "reviewed", reviewed
        );
    }

    @Override
    public ProductReview createReview(
            String productKey,
            String productName,
            UUID accountId,
            Integer rating,
            String comment,
            List<String> photoUrls) {

        if (rating == null || rating < 1 || rating > 5) {
            throw new RuntimeException("Rating must be from 1 to 5");
        }
        if (comment == null || comment.trim().isEmpty()) {
            throw new RuntimeException("Review comment cannot be empty");
        }
        if (productReviewRepository.existsByProductKeyAndAccountId(productKey, accountId)) {
            throw new RuntimeException("ACCOUNT_ALREADY_REVIEWED_PRODUCT");
        }

        StaffAccount account = staffAccountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Account not found with ID: " + accountId));
        String accountName = (account.getFirstName() + " " + account.getLastName()).trim();
        if (accountName.isEmpty()) {
            accountName = account.getEmail();
        }

        ProductReview review = ProductReview.builder()
                .productKey(productKey)
                .productName(productName)
                .account(account)
                .accountName(accountName)
                .rating(rating)
                .comment(comment.trim())
                .photoUrls(String.join(",", photoUrls == null ? List.of() : photoUrls))
                .build();

        return productReviewRepository.save(review);
    }

    @Override
    public String uploadPhoto(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new RuntimeException("Photo file cannot be empty");
        }

        Files.createDirectories(REVIEW_UPLOAD_DIR);
        String originalName = file.getOriginalFilename() == null ? "review.jpg" : file.getOriginalFilename();
        String extension = "";
        int dotIndex = originalName.lastIndexOf('.');
        if (dotIndex >= 0) {
            extension = originalName.substring(dotIndex);
        }

        String fileName = UUID.randomUUID() + extension;
        Path target = REVIEW_UPLOAD_DIR.resolve(fileName).normalize();
        Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);

        return "/uploads/reviews/" + fileName;
    }
}
