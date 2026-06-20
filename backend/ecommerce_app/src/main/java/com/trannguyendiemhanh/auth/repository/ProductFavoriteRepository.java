package com.trannguyendiemhanh.auth.repository;

import com.trannguyendiemhanh.auth.entity.ProductFavorite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductFavoriteRepository extends JpaRepository<ProductFavorite, UUID> {
    List<ProductFavorite> findByAccountIdOrderByCreatedAtDesc(UUID accountId);

    Optional<ProductFavorite> findByAccountIdAndProductKey(UUID accountId, String productKey);

    boolean existsByAccountIdAndProductKey(UUID accountId, String productKey);

    void deleteByAccountIdAndProductKey(UUID accountId, String productKey);
}
