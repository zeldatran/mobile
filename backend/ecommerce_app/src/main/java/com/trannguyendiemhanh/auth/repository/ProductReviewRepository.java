package com.trannguyendiemhanh.auth.repository;

import com.trannguyendiemhanh.auth.entity.ProductReview;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductReviewRepository extends JpaRepository<ProductReview, UUID> {
    List<ProductReview> findByProductKeyOrderByCreatedAtDesc(String productKey);

    Optional<ProductReview> findByProductKeyAndAccountId(String productKey, UUID accountId);

    boolean existsByProductKeyAndAccountId(String productKey, UUID accountId);

    long countByProductKey(String productKey);

    @Query("select coalesce(avg(r.rating), 0) from ProductReview r where r.productKey = :productKey")
    Double averageRatingByProductKey(String productKey);
}
