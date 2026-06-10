package com.trannguyendiemhanh.auth.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.trannguyendiemhanh.auth.entity.Product;
import com.trannguyendiemhanh.auth.entity.Tag;
import com.trannguyendiemhanh.auth.repository.ProductRepository;
import com.trannguyendiemhanh.auth.repository.TagRepository;
import com.trannguyendiemhanh.auth.service.ProductService;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;
    private final TagRepository tagRepository;

    @Autowired
    public ProductServiceImpl(
            ProductRepository productRepository,
            TagRepository tagRepository) {
        this.productRepository = productRepository;
        this.tagRepository = tagRepository;
    }

    @Override
    public Product createProduct(Product product) {
        if (productRepository.findBySlug(product.getSlug()).isPresent()) {
            throw new RuntimeException("Product with slug already exists: " + product.getSlug());
        }
        return productRepository.save(product);
    }

    @Override
    public Product getProductById(UUID id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found with ID: " + id));
    }

    @Override
    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    @Override
    public List<Product> getProductsByTagName(String tagName) {
        return productRepository.findByTagsTagNameIgnoreCase(tagName);
    }

    @Override
    public Product moveProductToTag(UUID id, String tagName) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found with ID: " + id));

        String normalizedTagName = tagName.trim().toLowerCase();
        if (!"new".equals(normalizedTagName) && !"sale".equals(normalizedTagName)) {
            throw new RuntimeException("Only 'new' and 'sale' tags can be moved with this endpoint");
        }

        Tag targetTag = tagRepository.findByTagNameIgnoreCase(normalizedTagName)
                .orElseThrow(() -> new RuntimeException("Tag not found: " + tagName));

        product.getTags().removeIf(tag ->
                "new".equalsIgnoreCase(tag.getTagName()) ||
                "sale".equalsIgnoreCase(tag.getTagName())
        );
        product.getTags().add(targetTag);

        return productRepository.save(product);
    }

    @Override
    public Product updateProduct(UUID id, Product product) {

        Product existing = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found with ID: " + id));

        existing.setSlug(product.getSlug());
        existing.setProductName(product.getProductName());
        existing.setSku(product.getSku());
        existing.setSalePrice(product.getSalePrice());
        existing.setComparePrice(product.getComparePrice());
        existing.setBuyingPrice(product.getBuyingPrice());
        existing.setQuantity(product.getQuantity());
        existing.setShortDescription(product.getShortDescription());
        existing.setProductDescription(product.getProductDescription());
        existing.setProductType(product.getProductType());
        existing.setPublished(product.getPublished());

        existing.setDisableOutOfStock(
                product.getDisableOutOfStock()
        );
        existing.setNote(product.getNote());
        existing.setImage(product.getImage());

        // Quan trọng nhất để đổi NEW ↔ SALE
        if (product.getTags() != null && !product.getTags().isEmpty()) {
            existing.setTags(resolveTags(product.getTags()));
        }

        return productRepository.save(existing);
    }

    private Set<Tag> resolveTags(Set<Tag> requestedTags) {
        Set<Tag> resolvedTags = new HashSet<>();

        for (Tag requestedTag : requestedTags) {
            if (requestedTag.getId() != null) {
                resolvedTags.add(tagRepository.findById(requestedTag.getId())
                        .orElseThrow(() -> new RuntimeException("Tag not found with ID: " + requestedTag.getId())));
            } else if (requestedTag.getTagName() != null && !requestedTag.getTagName().trim().isEmpty()) {
                resolvedTags.add(tagRepository.findByTagNameIgnoreCase(requestedTag.getTagName().trim())
                        .orElseThrow(() -> new RuntimeException("Tag not found: " + requestedTag.getTagName())));
            }
        }

        return resolvedTags;
    }

    @Override
    public void deleteProduct(UUID id) {
        productRepository.deleteById(id);
    }
}
