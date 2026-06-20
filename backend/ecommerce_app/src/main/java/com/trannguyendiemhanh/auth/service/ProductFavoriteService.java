package com.trannguyendiemhanh.auth.service;

import com.trannguyendiemhanh.auth.entity.ProductFavorite;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface ProductFavoriteService {
    List<ProductFavorite> getFavorites(UUID accountId);

    ProductFavorite addFavorite(Map<String, Object> payload);

    void removeFavorite(UUID accountId, String productKey);
}
