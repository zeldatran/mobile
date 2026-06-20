package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.ProductFavorite;
import com.trannguyendiemhanh.auth.entity.StaffAccount;
import com.trannguyendiemhanh.auth.repository.ProductFavoriteRepository;
import com.trannguyendiemhanh.auth.repository.StaffAccountRepository;
import com.trannguyendiemhanh.auth.service.ProductFavoriteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class ProductFavoriteServiceImpl implements ProductFavoriteService {

    private final ProductFavoriteRepository productFavoriteRepository;
    private final StaffAccountRepository staffAccountRepository;

    @Autowired
    public ProductFavoriteServiceImpl(
            ProductFavoriteRepository productFavoriteRepository,
            StaffAccountRepository staffAccountRepository) {
        this.productFavoriteRepository = productFavoriteRepository;
        this.staffAccountRepository = staffAccountRepository;
    }

    @Override
    public List<ProductFavorite> getFavorites(UUID accountId) {
        return productFavoriteRepository.findByAccountIdOrderByCreatedAtDesc(accountId);
    }

    @Override
    public ProductFavorite addFavorite(Map<String, Object> payload) {
        UUID accountId = UUID.fromString((String) payload.get("accountId"));
        String productKey = (String) payload.get("productKey");
        StaffAccount account = staffAccountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Account not found with ID: " + accountId));

        ProductFavorite favorite = productFavoriteRepository
                .findByAccountIdAndProductKey(accountId, productKey)
                .orElseGet(ProductFavorite::new);

        favorite.setAccount(account);
        favorite.setProductKey(productKey);
        favorite.setProductName((String) payload.get("productName"));
        favorite.setBrand((String) payload.get("brand"));
        favorite.setImage((String) payload.get("image"));
        favorite.setPrice(readInt(payload.get("price")));
        favorite.setOldPrice(readNullableInt(payload.get("oldPrice")));
        favorite.setDiscountPercent(readNullableInt(payload.get("discountPercent")));
        favorite.setRating(readDouble(payload.get("rating")));
        favorite.setReviews(readInt(payload.get("reviews")));
        favorite.setSize((String) payload.getOrDefault("size", "S"));
        favorite.setColor((String) payload.getOrDefault("color", "Black"));

        return productFavoriteRepository.save(favorite);
    }

    @Override
    @Transactional
    public void removeFavorite(UUID accountId, String productKey) {
        productFavoriteRepository.deleteByAccountIdAndProductKey(accountId, productKey);
    }

    private int readInt(Object value) {
        return value instanceof Number number ? number.intValue() : Integer.parseInt(String.valueOf(value));
    }

    private Integer readNullableInt(Object value) {
        if (value == null) return null;
        return readInt(value);
    }

    private double readDouble(Object value) {
        return value instanceof Number number ? number.doubleValue() : Double.parseDouble(String.valueOf(value));
    }
}
