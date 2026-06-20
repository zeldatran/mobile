package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.AttributeValue;
import com.trannguyendiemhanh.auth.repository.AttributeValueRepository;
import com.trannguyendiemhanh.auth.service.AttributeValueService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class AttributeValueServiceImpl extends JpaCrudServiceImpl<AttributeValue, UUID> implements AttributeValueService {
    public AttributeValueServiceImpl(AttributeValueRepository repository) {
        super(repository);
    }
}
