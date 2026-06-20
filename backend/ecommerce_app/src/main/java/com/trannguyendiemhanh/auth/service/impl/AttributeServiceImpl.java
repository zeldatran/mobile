package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Attribute;
import com.trannguyendiemhanh.auth.repository.AttributeRepository;
import com.trannguyendiemhanh.auth.service.AttributeService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class AttributeServiceImpl extends JpaCrudServiceImpl<Attribute, UUID> implements AttributeService {
    public AttributeServiceImpl(AttributeRepository repository) {
        super(repository);
    }
}
