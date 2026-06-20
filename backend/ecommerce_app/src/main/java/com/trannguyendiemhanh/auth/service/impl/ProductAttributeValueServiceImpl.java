package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.ProductAttributeValue;
import com.trannguyendiemhanh.auth.repository.ProductAttributeValueRepository;
import com.trannguyendiemhanh.auth.service.ProductAttributeValueService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ProductAttributeValueServiceImpl extends JpaCrudServiceImpl<ProductAttributeValue, UUID> implements ProductAttributeValueService {
    public ProductAttributeValueServiceImpl(ProductAttributeValueRepository repository) {
        super(repository);
    }
}
