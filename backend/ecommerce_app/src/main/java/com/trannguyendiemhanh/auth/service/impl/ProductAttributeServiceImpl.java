package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.ProductAttribute;
import com.trannguyendiemhanh.auth.repository.ProductAttributeRepository;
import com.trannguyendiemhanh.auth.service.ProductAttributeService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ProductAttributeServiceImpl extends JpaCrudServiceImpl<ProductAttribute, UUID> implements ProductAttributeService {
    public ProductAttributeServiceImpl(ProductAttributeRepository repository) {
        super(repository);
    }
}
