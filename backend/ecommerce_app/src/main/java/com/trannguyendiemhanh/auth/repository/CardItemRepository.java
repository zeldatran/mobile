package com.trannguyendiemhanh.auth.repository;

import com.trannguyendiemhanh.auth.entity.CardItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CardItemRepository extends JpaRepository<CardItem, UUID> {
    List<CardItem> findByCardAccountIdOrderById(UUID accountId);

    Optional<CardItem> findByCardIdAndProductKeyAndSizeAndColor(
            UUID cardId,
            String productKey,
            String size,
            String color
    );
}
