package com.trannguyendiemhanh.auth.service;

import java.util.List;
import java.util.UUID;

import com.trannguyendiemhanh.auth.entity.Product;

public interface ProductService {
    Product createProduct(Product product);
    Product getProductById(UUID id);
    List<Product> getAllProducts();
    List<Product> getProductsByTagName(String tagName);
    Product moveProductToTag(UUID id, String tagName);
    Product updateProduct(UUID id, Product product);
    void deleteProduct(UUID id);
}
